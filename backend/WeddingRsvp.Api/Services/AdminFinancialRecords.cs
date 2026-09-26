using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;

namespace WeddingRsvp.Api.Services;

// A checkout is visible before a payment webhook exists. Once real payments
// arrive they replace the order fallback, rather than being counted twice.
public static class AdminFinancialRecords
{
    public static IQueryable<FinancialRecord> Query(AppDbContext db)
    {
        var payments = db.Payments.AsNoTracking().Select(p => new FinancialRecord
        {
            Id = p.Id,
            OrderId = p.OrderId,
            GatewayPaymentId = p.GatewayPaymentId,
            Status = p.Status == "Pending" && p.Order != null &&
                (p.Order.Status == "Confirmed" || p.Order.Status == "Received" ||
                 p.Order.Status == "Refunded" || p.Order.Status == "Disputed" ||
                 p.Order.Status == "Cancelled" || p.Order.Status == "Overdue")
                ? p.Order.Status : p.Status,
            AmountCents = p.AmountCents,
            RefundedCents = p.RefundedCents,
            CreatedAtUtc = p.CreatedAtUtc,
            SenderName = p.Order != null ? p.Order.SenderName : null,
            Source = "Payment"
        });
        var orders = db.GiftOrders.AsNoTracking()
            .Where(o => !db.Payments.Any(p => p.OrderId == o.Id))
            .Select(o => new FinancialRecord
            {
                Id = o.Id,
                OrderId = o.Id,
                GatewayPaymentId = null,
                Status = o.Status == "Pending" && db.PaymentAttempts.Any(a =>
                    a.OrderId == o.Id && a.Status == "UnknownNeedsReview")
                    ? "UnknownNeedsReview" : o.Status,
                AmountCents = o.TotalCents,
                RefundedCents = 0,
                CreatedAtUtc = o.CreatedAtUtc,
                SenderName = o.SenderName,
                Source = "Order"
            });
        return payments.Concat(orders);
    }
}

public class FinancialRecord
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public string? GatewayPaymentId { get; set; }
    public string Status { get; set; } = "";
    public long AmountCents { get; set; }
    public long RefundedCents { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public string? SenderName { get; set; }
    public string Source { get; set; } = "";
}
