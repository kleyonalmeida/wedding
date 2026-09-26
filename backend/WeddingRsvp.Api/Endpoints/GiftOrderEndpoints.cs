using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Models;
using WeddingRsvp.Api.Payments;

namespace WeddingRsvp.Api.Endpoints;

public static class GiftOrderEndpoints
{
    public static void MapGiftOrderEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/gift-orders").WithTags("Public Gift Orders");

        group.MapPost("/", async (
            GiftOrderRequest request,
            AppDbContext db,
            IPaymentGateway paymentGateway,
            IConfiguration configuration,
            ILoggerFactory loggerFactory) =>
        {
            if (string.IsNullOrWhiteSpace(request.SenderName) || request.SenderName.Length > 100 || request.Message?.Length > 500 || request.Items == null || !request.Items.Any() || request.Items.Count > 50 || request.Items.Any(i => i.Quantity < 1 || i.Quantity > 100) || request.Items.Select(i => i.GiftId).Distinct().Count() != request.Items.Count ||
                request.IdempotencyKey?.Length != 64 || !request.IdempotencyKey.All(Uri.IsHexDigit))
            {
                return Results.BadRequest("SenderName and Items are required.");
            }
            var canonicalItems = request.Items.OrderBy(i => i.GiftId)
                .Select(i => new { i.GiftId, i.Quantity }).ToArray();
            var requestHash = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(
                System.Text.Encoding.UTF8.GetBytes(System.Text.Json.JsonSerializer.Serialize(new
                {
                    SenderName = request.SenderName.Trim(),
                    Message = request.Message?.Trim(),
                    Items = canonicalItems
                }))));
            var previous = await db.PaymentAttempts.Include(a => a.Order)
                .FirstOrDefaultAsync(a => a.IdempotencyKey == request.IdempotencyKey);
            if (previous != null)
            {
                if (previous.RequestHash != requestHash) return Results.Conflict("Idempotency key reused for a different order.");
                if (previous.CheckoutUrl != null && previous.Order != null)
                    return Results.Ok(new GiftOrderResponse(previous.OrderId, previous.CheckoutUrl, request.IdempotencyKey));
                return Results.Conflict("This order is being reconciled. Contact the administrator before retrying.");
            }

            // A resposta do provedor pode se perder depois que o checkout foi criado.
            // Evita uma segunda cobranca para o mesmo pedido com uma nova chave.
            var unresolvedDuplicate = await db.PaymentAttempts.AnyAsync(a =>
                a.RequestHash == requestHash && a.CheckoutUrl == null &&
                (a.Status == "Pending" || a.Status == "UnknownNeedsReview"));
            if (unresolvedDuplicate)
                return Results.Conflict("An identical order is being reconciled. Contact the administrator before retrying.");

            var giftIds = request.Items.Select(i => i.GiftId).ToList();
            var gifts = await db.Set<Gift>()
                .Where(g => giftIds.Contains(g.Id) && g.Active && g.DeletedAtUtc == null)
                .ToListAsync();

            if (gifts.Count != giftIds.Count)
            {
                return Results.BadRequest("One or more gifts are invalid, inactive, or not found.");
            }
            await using var stockTransaction = db.Database.IsRelational()
                ? await db.Database.BeginTransactionAsync() : null;

            foreach (var itemReq in request.Items)
            {
                var gift = gifts.First(g => g.Id == itemReq.GiftId);
                if (!await GiftInventory.ReserveAsync(db, gift, itemReq.Quantity))
                {
                    if (stockTransaction != null) await stockTransaction.RollbackAsync();
                    return Results.Conflict("Um dos presentes foi esgotado. Atualize a lista e tente novamente.");
                }
            }

            var order = new GiftOrder
            {
                Id = Guid.NewGuid(),
                SenderName = request.SenderName,
                Message = request.Message,
                Currency = "BRL",
                Status = "Pending",
                CreatedAtUtc = DateTimeOffset.UtcNow,
                Version = Guid.NewGuid()
            };
            var accessToken = request.IdempotencyKey;
            order.PublicTokenHash = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(accessToken)));

            long totalCents = 0;
            foreach (var itemReq in request.Items)
            {
                var gift = gifts.First(g => g.Id == itemReq.GiftId);
                var item = new GiftOrderItem
                {
                    Id = Guid.NewGuid(),
                    OrderId = order.Id,
                    GiftId = gift.Id,
                    Quantity = itemReq.Quantity,
                    ReservedQuantity = gift.StockRemaining == null ? 0 : itemReq.Quantity,
                    PriceCentsSnapshot = gift.PriceCents,
                    GiftNameSnapshot = gift.Name
                };
                totalCents += gift.PriceCents * itemReq.Quantity;
                order.Items.Add(item);
            }
            order.TotalCents = totalCents;

            var attempt = new PaymentAttempt
            {
                Id = Guid.NewGuid(),
                OrderId = order.Id,
                Gateway = "Asaas",
                Environment = configuration["Asaas:Environment"] ?? "Sandbox",
                IdempotencyKey = request.IdempotencyKey,
                RequestHash = requestHash,
                Status = "Pending",
                CreatedAtUtc = DateTimeOffset.UtcNow,
                Version = Guid.NewGuid()
            };

            db.Add(order);
            db.Add(attempt);
            await db.SaveChangesAsync(); // Save first to have IDs in DB
            if (stockTransaction != null) await stockTransaction.CommitAsync();

            try
            {
                var checkoutResponse = await paymentGateway.CreateCheckoutAsync(attempt, order, accessToken);
                attempt.GatewayCheckoutId = checkoutResponse.CheckoutId;
                attempt.CheckoutUrl = checkoutResponse.CheckoutUrl;
                attempt.UpdatedAtUtc = DateTimeOffset.UtcNow;
                await db.SaveChangesAsync();

                return Results.Ok(new GiftOrderResponse(order.Id, attempt.CheckoutUrl!, accessToken));
            }
            catch (Exception ex)
            {
                loggerFactory.CreateLogger(nameof(GiftOrderEndpoints))
                    .LogError(ex, "Checkout creation failed for attempt {AttemptId} and order {OrderId}", attempt.Id, order.Id);
                attempt.Status = "UnknownNeedsReview";
                attempt.UpdatedAtUtc = DateTimeOffset.UtcNow;
                await db.SaveChangesAsync();
                return Results.Problem("Payment gateway error", statusCode: 502);
            }
        }).RequireRateLimiting("OrderPolicy");

        group.MapGet("/{id:guid}", async (Guid id, string? token, AppDbContext db) =>
        {
            if (string.IsNullOrWhiteSpace(token)) return Results.Unauthorized();
            var order = await db.Set<GiftOrder>()
                .Where(o => o.Id == id && o.PublicTokenHash == Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(token))))
                .Select(o => new
                {
                    o.Id,
                    o.Status,
                    CheckoutUrl = db.Set<PaymentAttempt>()
                        .Where(a => a.OrderId == o.Id)
                        .OrderByDescending(a => a.CreatedAtUtc)
                        .Select(a => a.CheckoutUrl)
                        .FirstOrDefault()
                })
                .FirstOrDefaultAsync();

            if (order == null) return Results.NotFound();
            return Results.Ok(order);
        });
    }
}
