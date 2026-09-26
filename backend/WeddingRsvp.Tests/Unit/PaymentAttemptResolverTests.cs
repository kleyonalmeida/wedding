using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Payments;

namespace WeddingRsvp.Tests.Unit;

public class PaymentAttemptResolverTests
{
    [Fact]
    public async Task CheckoutSessionResolvesPaymentWithoutExternalReference()
    {
        using var db = CreateDb();
        var attempt = await Seed(db, "session-test");
        var resolved = await PaymentAttemptResolver.ResolveAsync(db, null, "session-test");
        Assert.Equal(attempt.Id, resolved.Id);
        Assert.Equal(12500, resolved.Order!.TotalCents);
        Assert.Equal(attempt.Id, (await PaymentAttemptResolver.ResolveAsync(db,
            attempt.Id.ToString(), null)).Id);
        Assert.Equal(attempt.Id, (await PaymentAttemptResolver.ResolveAsync(db,
            null, null, attempt.Id)).Id);
    }

    [Fact]
    public async Task ConflictingOrMissingReferencesCannotLinkToAnotherOrder()
    {
        using var db = CreateDb();
        var first = await Seed(db, "first-session");
        var second = await Seed(db, "second-session");
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            PaymentAttemptResolver.ResolveAsync(db, first.Id.ToString(), "second-session"));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            PaymentAttemptResolver.ResolveAsync(db, first.Id.ToString(), "first-session", second.Id));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            PaymentAttemptResolver.ResolveAsync(db, null, "unknown-session"));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            PaymentAttemptResolver.ResolveAsync(db, null, null));
    }

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static async Task<PaymentAttempt> Seed(AppDbContext db, string checkoutId)
    {
        var order = new GiftOrder { Id = Guid.NewGuid(), TotalCents = 12500 };
        var attempt = new PaymentAttempt { Id = Guid.NewGuid(), Order = order,
            OrderId = order.Id, GatewayCheckoutId = checkoutId };
        db.Add(attempt);
        await db.SaveChangesAsync();
        return attempt;
    }
}
