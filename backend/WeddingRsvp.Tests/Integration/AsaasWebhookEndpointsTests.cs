using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using WeddingRsvp.Api.Data;

namespace WeddingRsvp.Tests.Integration;

public class AsaasWebhookEndpointsTests
{
    [Theory]
    [InlineData(null)]
    [InlineData("wrong-token")]
    public async Task MissingOrDifferentWebhookTokenReturns401(string? token)
    {
        using var factory = new Factory();
        using var client = factory.CreateClient();
        if (token != null) client.DefaultRequestHeaders.Add("asaas-access-token", token);
        var response = await client.PostAsJsonAsync("/api/webhooks/asaas", Payload());
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        using var scope = factory.Services.CreateScope();
        Assert.Empty(scope.ServiceProvider.GetRequiredService<AppDbContext>().AsaasWebhookEvents);
    }

    [Fact]
    public async Task CorrectTokenAcceptsCheckoutSessionWithNullExternalReference()
    {
        using var factory = new Factory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("asaas-access-token", "webhook-test-token");
        var response = await client.PostAsJsonAsync("/api/webhooks/asaas", Payload());
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var scope = factory.Services.CreateScope();
        var evt = Assert.Single(scope.ServiceProvider.GetRequiredService<AppDbContext>().AsaasWebhookEvents);
        Assert.Equal("pay-test", evt.GatewayPaymentId);
        Assert.Equal("session-test", evt.GatewayCheckoutId);
        Assert.Equal("Pending", evt.Status);
    }

    private static object Payload() => new
    {
        id = "evt-test", @event = "PAYMENT_CREATED",
        payment = new { id = "pay-test", checkoutSession = "session-test",
            externalReference = (string?)null, value = 125m, netValue = 124.01m,
            billingType = "PIX", status = "PENDING" }
    };

    private sealed class Factory : CustomWebApplicationFactory
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            base.ConfigureWebHost(builder);
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(
                new Dictionary<string, string?> { ["Asaas:WebhookAuthToken"] = "webhook-test-token" }));
        }
    }
}
