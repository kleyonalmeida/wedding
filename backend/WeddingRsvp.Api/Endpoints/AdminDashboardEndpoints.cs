using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminDashboardEndpoints
{
    public static void MapAdminDashboardEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/dashboard")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        group.MapGet("/summary", async (AppDbContext db) =>
        {
            // RSVPs
            var rsvps = await db.Rsvps.AsNoTracking().ToListAsync();
            var confirmados = rsvps.Where(r => r.VaiComparecer).ToList();
            var recusados = rsvps.Where(r => !r.VaiComparecer).ToList();
            var totalPessoas = confirmados.Sum(r => r.QtdAdultos + r.QtdCriancas);

            // Produtos
            var gifts = await db.Gifts.AsNoTracking().ToListAsync();
            var totalGifts = gifts.Count;
            var activeGifts = gifts.Count(g => g.Active && g.DeletedAtUtc == null);
            var inactiveGifts = totalGifts - activeGifts;

            // Pedidos confirmados por webhook de checkout ou cobrança.
            var paidOrders = await db.GiftOrders.AsNoTracking().CountAsync(o => o.Status == "Confirmed" || o.Status == "Received");
            
            var payments = await db.Payments.AsNoTracking().ToListAsync();
            var pendingPayments = payments.Count(p => p.Status == "Pending");
            var confirmedPayments = payments.Count(p => p.Status == "Confirmed");
            var cancelledPayments = payments.Count(p => p.Status == "Cancelled" || p.Status == "Overdue");
            
            // Receita apenas de pagamentos Received
            var receivedPayments = payments.Where(p => p.Status == "Received").ToList();
            var totalReceivedCents = receivedPayments.Sum(p => p.AmountCents - p.RefundedCents);

            return Results.Ok(new
            {
                rsvps = new
                {
                    total = rsvps.Count,
                    confirmados = confirmados.Count,
                    recusados = recusados.Count,
                    totalPessoas
                },
                products = new
                {
                    total = totalGifts,
                    ativos = activeGifts,
                    inativos = inactiveGifts
                },
                orders = new
                {
                    paidOrders
                },
                payments = new
                {
                    pending = pendingPayments,
                    confirmed = confirmedPayments,
                    cancelled = cancelledPayments,
                    totalReceivedCents
                }
            });
        });

        group.MapGet("/activity", async (AppDbContext db, int limit = 10) =>
        {
            var activities = await db.AuditLogs
                .AsNoTracking()
                .OrderByDescending(a => a.TimestampUtc)
                .Take(limit)
                .Select(a => new
                {
                    a.Id,
                    a.TimestampUtc,
                    a.Action,
                    a.EntityType,
                    a.Description
                })
                .ToListAsync();

            return Results.Ok(activities);
        });
    }
}
