using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Tests.Integration;

public class AdminFinancialEndpointsTests
{
    [Fact]
    public async Task CheckoutIsVisibleBeforePaymentAndReconciliationDoesNotDoubleCount()
    {
        using var factory = new CustomWebApplicationFactory();
        using var client = factory.CreateClient();
        var login = await client.PostAsJsonAsync("/api/admin/auth/login",
            new AdminLoginRequest("admin@wedding.com", "Admin@123!"));
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var cookie = login.Headers.GetValues("Set-Cookie").First(c => c.StartsWith(".Wedding.Admin"));
        client.DefaultRequestHeaders.Add("Cookie", cookie.Split(';')[0]);

        var orderId = Guid.NewGuid();
        var attemptId = Guid.NewGuid();
        var paymentId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.GiftOrders.Add(new GiftOrder { Id = orderId, SenderName = "Convidado",
                Message = "Felicidades", TotalCents = 5200, Status = "Pending",
                CreatedAtUtc = DateTimeOffset.UtcNow });
            db.PaymentAttempts.Add(new PaymentAttempt { Id = attemptId, OrderId = orderId,
                GatewayCheckoutId = "checkout-test", Status = "Pending",
                IdempotencyKey = new string('F', 64), CreatedAtUtc = DateTimeOffset.UtcNow });
            db.AsaasWebhookEvents.Add(new AsaasWebhookEvent { Id = Guid.NewGuid(),
                AsaasEventId = "evt-checkout", GatewayCheckoutId = "checkout-test",
                EventType = "CHECKOUT_CREATED", Payload = "{}", Status = "Processed",
                ReceivedAtUtc = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }

        await AssertSummary(client, pending: 1, raised: 0, received: 0);
        await AssertSingleRecord(client, orderId, "Order", "Pending");
        var detail = await client.GetFromJsonAsync<JsonElement>($"/api/admin/payments/{orderId}");
        Assert.False(detail.GetProperty("canSync").GetBoolean());
        Assert.Equal(JsonValueKind.Null, detail.GetProperty("netCents").ValueKind);
        Assert.Equal("Felicidades", detail.GetProperty("order").GetProperty("message").GetString());
        var events = await client.GetFromJsonAsync<JsonElement>($"/api/admin/payments/{orderId}/events");
        Assert.Single(events.EnumerateArray());

        // CHECKOUT_PAID updates the order without manufacturing a payment ID.
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            (await db.GiftOrders.FindAsync(orderId))!.Status = "Confirmed";
            await db.SaveChangesAsync();
        }
        await AssertSummary(client, pending: 0, raised: 5200, received: 0);
        await AssertSingleRecord(client, orderId, "Order", "Confirmed");

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Payments.Add(new Payment { Id = paymentId, OrderId = orderId, AttemptId = attemptId,
                GatewayPaymentId = "pay-test", AmountCents = 5200, Status = "Pending",
                BillingType = "CREDIT_CARD", CreatedAtUtc = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }
        await AssertSummary(client, pending: 0, raised: 5200, received: 0);
        await AssertSingleRecord(client, paymentId, "Payment", "Confirmed");
        var paymentDetail = await client.GetFromJsonAsync<JsonElement>($"/api/admin/payments/{paymentId}");
        Assert.True(paymentDetail.GetProperty("canSync").GetBoolean());
        var oldLink = await client.GetFromJsonAsync<JsonElement>($"/api/admin/payments/{orderId}");
        Assert.Equal(paymentId, oldLink.GetProperty("id").GetGuid());
        Assert.True(oldLink.GetProperty("canSync").GetBoolean());

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            (await db.Payments.FindAsync(paymentId))!.Status = "Received";
            (await db.GiftOrders.FindAsync(orderId))!.Status = "Received";
            await db.SaveChangesAsync();
        }
        await AssertSummary(client, pending: 0, raised: 5200, received: 5200);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            (await db.Payments.FindAsync(paymentId))!.Status = "Refunded";
            (await db.GiftOrders.FindAsync(orderId))!.Status = "Refunded";
            await db.SaveChangesAsync();
        }
        await AssertSummary(client, pending: 0, raised: 0, received: 0);
    }

    [Fact]
    public async Task UncertainCheckoutIsNotCountedAsPendingOrRevenue()
    {
        using var factory = new CustomWebApplicationFactory();
        using var client = factory.CreateClient();
        var login = await client.PostAsJsonAsync("/api/admin/auth/login",
            new AdminLoginRequest("admin@wedding.com", "Admin@123!"));
        var cookie = login.Headers.GetValues("Set-Cookie").First(c => c.StartsWith(".Wedding.Admin"));
        client.DefaultRequestHeaders.Add("Cookie", cookie.Split(';')[0]);
        var orderId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.GiftOrders.Add(new GiftOrder { Id = orderId, Status = "Pending", TotalCents = 5200 });
            db.PaymentAttempts.Add(new PaymentAttempt { Id = Guid.NewGuid(), OrderId = orderId,
                Status = "UnknownNeedsReview", IdempotencyKey = new string('U', 64) });
            await db.SaveChangesAsync();
        }
        await AssertSummary(client, pending: 0, raised: 0, received: 0);
        await AssertSingleRecord(client, orderId, "Order", "UnknownNeedsReview");
    }

    private static async Task AssertSummary(HttpClient client, int pending, long raised, long received)
    {
        var summary = await client.GetFromJsonAsync<JsonElement>("/api/admin/dashboard/summary");
        var payments = summary.GetProperty("payments");
        Assert.Equal(pending, payments.GetProperty("pending").GetInt32());
        Assert.Equal(raised, payments.GetProperty("totalRaisedCents").GetInt64());
        Assert.Equal(received, payments.GetProperty("totalReceivedCents").GetInt64());
        Assert.Equal(raised - received, payments.GetProperty("totalConfirmedCents").GetInt64());
    }

    private static async Task AssertSingleRecord(HttpClient client, Guid id, string source, string status)
    {
        var response = await client.GetFromJsonAsync<JsonElement>("/api/admin/payments?page=1&pageSize=3");
        Assert.Equal(1, response.GetProperty("total").GetInt32());
        var row = Assert.Single(response.GetProperty("items").EnumerateArray());
        Assert.Equal(id, row.GetProperty("id").GetGuid());
        Assert.Equal(source, row.GetProperty("source").GetString());
        Assert.Equal(status, row.GetProperty("status").GetString());
    }
}
