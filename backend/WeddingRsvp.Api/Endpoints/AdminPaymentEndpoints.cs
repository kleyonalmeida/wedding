using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminPaymentEndpoints
{
    public static void MapAdminPaymentEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/admin/payments")
            .RequireAuthorization("SuperAdmin")
            .RequireRateLimiting("AdminPolicy")
            .WithTags("Admin Payments");

        group.MapGet("/", async (AppDbContext db, int page = 1, int pageSize = 20) =>
        {
            var query = db.Set<Payment>()
                .Include(p => p.Order)
                .OrderByDescending(p => p.CreatedAtUtc);

            var total = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
                .Select(p => new
                {
                    p.Id,
                    p.GatewayPaymentId,
                    p.Status,
                    p.AmountCents,
                    p.CreatedAtUtc,
                    SenderName = p.Order != null ? p.Order.SenderName : null
                })
                .ToListAsync();

            return Results.Ok(new { items, total, page, pageSize });
        });

        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var payment = await db.Set<Payment>()
                .Include(p => p.Order)
                .ThenInclude(o => o!.Items)
                .ThenInclude(i => i.Gift)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (payment == null) return Results.NotFound();

            return Results.Ok(new
            {
                payment.Id,
                payment.GatewayPaymentId,
                payment.Status,
                payment.AmountCents,
                payment.NetCents,
                payment.BillingType,
                payment.CreatedAtUtc,
                payment.ConfirmedAtUtc,
                payment.ReceivedAtUtc,
                Order = payment.Order != null ? new
                {
                    payment.Order.Id,
                    payment.Order.SenderName,
                    payment.Order.Message,
                    Items = payment.Order.Items.Select(i => new
                    {
                        i.Quantity,
                        Name = i.GiftNameSnapshot,
                        PriceCents = i.PriceCentsSnapshot
                    })
                } : null
            });
        });

        group.MapGet("/{id:guid}/events", async (Guid id, AppDbContext db) =>
        {
            var payment = await db.Set<Payment>().FindAsync(id);
            if (payment == null) return Results.NotFound();

            var events = await db.Set<AsaasWebhookEvent>()
                .Where(e => e.GatewayPaymentId == payment.GatewayPaymentId)
                .OrderByDescending(e => e.ReceivedAtUtc)
                .Select(e => new
                {
                    e.Id,
                    e.EventType,
                    e.Status,
                    e.ReceivedAtUtc,
                    e.ProcessedAtUtc,
                    e.ErrorCode
                })
                .ToListAsync();

            return Results.Ok(events);
        });

        group.MapPost("/{id:guid}/sync", async (Guid id, AppDbContext db, WeddingRsvp.Api.Payments.IPaymentGateway gateway, WeddingRsvp.Api.Services.IAuditService audit) =>
        {
            using var transaction = await db.Database.BeginTransactionAsync();
            try
            {
                var payment = await db.Set<Payment>().Include(p => p.Order).FirstOrDefaultAsync(p => p.Id == id);
                if (payment == null) return Results.NotFound();

                var statusResponse = await gateway.GetPaymentStatusAsync(payment.GatewayPaymentId);
                var newStatus = WeddingRsvp.Api.Payments.PaymentStatusMapper.MapAsaasStatus(statusResponse.Status);
                if (newStatus == "UnknownNeedsReview") return Results.Problem("Status de pagamento não reconhecido.", statusCode: 409);

                payment.Status = newStatus;
                payment.NetCents = statusResponse.NetCents;
                payment.UpdatedAtUtc = DateTimeOffset.UtcNow;

                if (newStatus == "Confirmed" && payment.ConfirmedAtUtc == null)
                    payment.ConfirmedAtUtc = DateTimeOffset.UtcNow;
                if (newStatus == "Received" && payment.ReceivedAtUtc == null)
                    payment.ReceivedAtUtc = DateTimeOffset.UtcNow;

                if (payment.Order != null)
                {
                    payment.Order.Status = newStatus;
                    payment.Order.UpdatedAtUtc = DateTimeOffset.UtcNow;
                }

                await audit.LogAsync(
                    action: "PaymentSync",
                    entityType: "Payment",
                    entityId: payment.Id.ToString(),
                    description: $"Manual sync updated status to {newStatus}"
                );

                await db.SaveChangesAsync();
                await transaction.CommitAsync();

                return Results.Ok(new { success = true, status = newStatus });
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                return Results.Problem("Não foi possível sincronizar o pagamento.");
            }
        });
    }
}
