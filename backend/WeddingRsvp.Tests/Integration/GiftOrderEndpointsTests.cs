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
        Assert.Equal(2500, status.GetProperty("totalCents").GetInt64());
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
