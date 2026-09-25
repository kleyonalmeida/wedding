using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Payments;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class GiftOrderEndpointsTests
{
    [Fact]
    public async Task RepeatedRequestReturnsSameCheckoutAndRequiresAccessToken()
    {
        using var factory = new Factory();
        using var client = factory.CreateClient();
        var giftId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Gifts.Add(new Gift
            {
                Id = giftId, Name = "Presente", Slug = "order-test", Category = "Casa",
                PriceCents = 1250, Active = true, CreatedAtUtc = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }
        var key = new string('A', 64);
        var request = new
        {
            senderName = "Convidado", message = "Felicidades",
            items = new[] { new { giftId, quantity = 2 } }, idempotencyKey = key
        };
        var first = await client.PostAsJsonAsync("/api/gift-orders", request);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        var firstBody = await first.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var id = firstBody.GetProperty("id").GetString();
        var repeated = await client.PostAsJsonAsync("/api/gift-orders", request);
        Assert.Equal(HttpStatusCode.OK, repeated.StatusCode);
        var repeatedBody = await repeated.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.Equal(id, repeatedBody.GetProperty("id").GetString());
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync($"/api/gift-orders/{id}")).StatusCode);
        var status = await client.GetFromJsonAsync<System.Text.Json.JsonElement>($"/api/gift-orders/{id}?token={key}");
        Assert.False(status.TryGetProperty("totalCents", out _));
    }

    [Fact]
    public async Task FiniteStockIsReservedAndPriceButNotStockIsPublic()
    {
        using var factory = new Factory();
        using var client = factory.CreateClient();
        var giftId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Gifts.Add(new Gift
            {
                Id = giftId, Name = "Presente limitado", Slug = "limited-gift", Category = "Casa",
                PriceCents = 4321, StockRemaining = 1, ExternalUrl = "https://example.com/produto",
                Active = true, CreatedAtUtc = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }
        var publicGift = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/gifts/limited-gift");
        Assert.False(publicGift.GetProperty("soldOut").GetBoolean());
        Assert.Equal(4321, publicGift.GetProperty("priceCents").GetInt64());
        var catalog = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/gifts");
        Assert.Equal(4321, catalog.EnumerateArray().Single(g => g.GetProperty("id").GetGuid() == giftId)
            .GetProperty("priceCents").GetInt64());
        Assert.False(publicGift.TryGetProperty("stockRemaining", out _));
        Assert.False(publicGift.TryGetProperty("externalUrl", out _));

        var first = await client.PostAsJsonAsync("/api/gift-orders", new
        {
            senderName = "Primeiro", items = new[] { new { giftId, quantity = 1 } },
            idempotencyKey = new string('C', 64)
        });
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        var second = await client.PostAsJsonAsync("/api/gift-orders", new
        {
            senderName = "Segundo", items = new[] { new { giftId, quantity = 1 } },
            idempotencyKey = new string('D', 64)
        });
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
        publicGift = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/gifts/limited-gift");
        Assert.True(publicGift.GetProperty("soldOut").GetBoolean());

        using var verifyScope = factory.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(0, (await verifyDb.Gifts.FindAsync(giftId))!.StockRemaining);
        Assert.Equal(1, verifyDb.GiftOrderItems.Single().ReservedQuantity);
    }

    [Fact]
    public async Task CancelledCheckoutReleasesReservationOnlyOnce()
    {
        using var factory = new Factory();
        using var client = factory.CreateClient();
        var giftId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Gifts.Add(new Gift
            {
                Id = giftId, Name = "Presente", Slug = "release-gift", Category = "Casa",
                PriceCents = 1000, StockRemaining = 1, Active = true
            });
            await db.SaveChangesAsync();
        }
        var response = await client.PostAsJsonAsync("/api/gift-orders", new
        {
            senderName = "Convidado", items = new[] { new { giftId, quantity = 1 } },
            idempotencyKey = new string('E', 64)
        });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var releaseScope = factory.Services.CreateScope();
        var releaseDb = releaseScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var order = releaseDb.GiftOrders.Single();
        await GiftInventory.ReleaseAsync(releaseDb, order);
        await releaseDb.SaveChangesAsync();
        await GiftInventory.ReleaseAsync(releaseDb, order);
        await releaseDb.SaveChangesAsync();
        Assert.Equal(1, (await releaseDb.Gifts.FindAsync(giftId))!.StockRemaining);
        Assert.True(order.StockReleased);
    }

    [Fact]
    public async Task UncertainCheckoutBlocksSameOrderWithAnotherKey()
    {
        using var factory = new Factory(failCheckout: true);
        using var client = factory.CreateClient();
        var giftId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Gifts.Add(new Gift
            {
                Id = giftId, Name = "Presente", Slug = "uncertain-order", Category = "Casa",
                PriceCents = 1250, Active = true, CreatedAtUtc = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }
        var first = await client.PostAsJsonAsync("/api/gift-orders", new
        {
            senderName = "Convidado", message = "Felicidades",
            items = new[] { new { giftId, quantity = 2 } }, idempotencyKey = new string('A', 64)
        });
        Assert.Equal(HttpStatusCode.BadGateway, first.StatusCode);
        var second = await client.PostAsJsonAsync("/api/gift-orders", new
        {
            senderName = "Convidado", message = "Felicidades",
            items = new[] { new { giftId, quantity = 2 } }, idempotencyKey = new string('B', 64)
        });
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    private sealed class Factory : CustomWebApplicationFactory
    {
        private readonly bool _failCheckout;

        public Factory(bool failCheckout = false) => _failCheckout = failCheckout;

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            base.ConfigureWebHost(builder);
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IPaymentGateway>();
                services.AddSingleton<IPaymentGateway>(new FakeGateway(_failCheckout));
            });
        }
    }

    private sealed class FakeGateway : IPaymentGateway
    {
        private readonly bool _failCheckout;

        public FakeGateway(bool failCheckout) => _failCheckout = failCheckout;

        public Task<GatewayCheckoutResponse> CreateCheckoutAsync(PaymentAttempt attempt, GiftOrder order, string accessToken, CancellationToken cancellationToken = default) =>
            _failCheckout
                ? Task.FromException<GatewayCheckoutResponse>(new HttpRequestException("Connection lost"))
                : Task.FromResult(new GatewayCheckoutResponse("checkout-test", "https://sandbox.asaas.com/checkoutSession/show/checkout-test"));

        public Task<GatewayPaymentResponse> GetPaymentStatusAsync(string gatewayPaymentId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new GatewayPaymentResponse("PENDING", 0, "PIX"));
    }
}
