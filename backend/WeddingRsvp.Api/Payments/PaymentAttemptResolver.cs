using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Payments;

public static class PaymentAttemptResolver
{
    public static async Task<PaymentAttempt> ResolveAsync(AppDbContext db,
        string? externalReference, string? checkoutSession, Guid? knownAttemptId = null,
        CancellationToken cancellationToken = default)
    {
        Guid? referenceId = null;
        if (!string.IsNullOrWhiteSpace(externalReference))
        {
            if (!Guid.TryParse(externalReference, out var id))
                throw new InvalidOperationException("Invalid payment external reference.");
            referenceId = id;
        }
        var attemptId = knownAttemptId ?? referenceId;
        PaymentAttempt? attempt;
        if (attemptId != null)
            attempt = await db.PaymentAttempts.Include(a => a.Order)
                .FirstOrDefaultAsync(a => a.Id == attemptId, cancellationToken);
        else if (!string.IsNullOrWhiteSpace(checkoutSession))
            attempt = await db.PaymentAttempts.Include(a => a.Order)
                .FirstOrDefaultAsync(a => a.GatewayCheckoutId == checkoutSession, cancellationToken);
        else
            throw new InvalidOperationException("Payment has no order reference or checkout session.");

        if (attempt?.Order == null)
            throw new InvalidOperationException("Payment attempt or order not found.");
        if ((referenceId != null && attempt.Id != referenceId) ||
            (!string.IsNullOrWhiteSpace(checkoutSession) && attempt.GatewayCheckoutId != checkoutSession))
            throw new InvalidOperationException("Payment references do not match checkout attempt.");
        return attempt;
    }
}
