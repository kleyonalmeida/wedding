using System.Reflection;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Payments;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Tests.Unit;

public class WebhookProcessorTests
{
    [Theory]
    [InlineData("PENDING", "PAYMENT_CREATED", "Pending")]
    [InlineData("RECEIVED", "PAYMENT_RECEIVED", "Received")]
    public async Task PaymentWithoutExternalReferenceUpdatesOrderAndFinancialRecords(
        string gatewayStatus, string eventType, string expectedStatus)
    {
        using var services = CreateServices();
        var orderId = await SeedEvent(services, gatewayStatus, eventType, 125m);
        await Process(services);
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(expectedStatus, (await db.GiftOrders.FindAsync(orderId))!.Status);
        var payment = Assert.Single(db.Payments);
        Assert.Equal(expectedStatus, payment.Status);
        Assert.Equal(12500, payment.AmountCents);
        Assert.Equal(12401, payment.NetCents);
        Assert.Equal("Processed", Assert.Single(db.AsaasWebhookEvents).Status);
        Assert.Single(await AdminFinancialRecords.Query(db).ToListAsync());
        await Process(services);
        Assert.Single(db.Payments);
    }

    [Fact]
    public async Task WrongAmountDoesNotConfirmOrderOrCreatePayment()
    {
        using var services = CreateServices();
        var orderId = await SeedEvent(services, "RECEIVED", "PAYMENT_RECEIVED", 999m);
        await Process(services);
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal("Pending", (await db.GiftOrders.FindAsync(orderId))!.Status);
        Assert.Empty(db.Payments);
        var evt = Assert.Single(db.AsaasWebhookEvents);
        Assert.Equal("Pending", evt.Status);
        Assert.Equal(1, evt.Attempts);
        Assert.Equal("InvalidOperationException", evt.ErrorCode);
    }

    private static ServiceProvider CreateServices()
    {
        var database = Guid.NewGuid().ToString();
        return new ServiceCollection()
            .AddDbContext<AppDbContext>(options => options.UseInMemoryDatabase(database)
                .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning)))
            .AddHttpContextAccessor().AddScoped<IAuditService, AuditService>().BuildServiceProvider();
    }

    private static async Task<Guid> SeedEvent(ServiceProvider services, string status, string eventType, decimal amount)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var order = new GiftOrder { Id = Guid.NewGuid(), TotalCents = 12500, Status = "Pending" };
        db.PaymentAttempts.Add(new PaymentAttempt { Id = Guid.NewGuid(), Order = order,
            OrderId = order.Id, GatewayCheckoutId = "session-test", Environment = "Sandbox" });
        db.AsaasWebhookEvents.Add(new AsaasWebhookEvent { Id = Guid.NewGuid(),
            AsaasEventId = "evt-test", EventType = eventType, GatewayPaymentId = "pay-test",
            GatewayCheckoutId = "session-test", Status = "Pending", ReceivedAtUtc = DateTimeOffset.UtcNow,
            Payload = JsonSerializer.Serialize(new { payment = new { id = "pay-test", status,
                externalReference = (string?)null, checkoutSession = "session-test", value = amount,
                netValue = 124.01m, billingType = "PIX" } }) });
        await db.SaveChangesAsync();
        return order.Id;
    }

    private static async Task Process(ServiceProvider services)
    {
        using var processor = new WebhookProcessor(services, NullLogger<WebhookProcessor>.Instance);
        // Drive one background batch deterministically, without timers or external Asaas calls.
        var method = typeof(WebhookProcessor).GetMethod("ProcessPendingWebhooksAsync",
            BindingFlags.Instance | BindingFlags.NonPublic)!;
        await (Task)method.Invoke(processor, new object[] { CancellationToken.None })!;
    }
}
