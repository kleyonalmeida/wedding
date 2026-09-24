using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Payments;
using Xunit;

namespace WeddingRsvp.Tests.Unit;

public class AsaasPaymentGatewayTests
{
    [Fact]
    public async Task CreateCheckout_SendsItemsAndReturnsProviderLink()
    {
        string? payload = null;
        var handler = new StubHandler(async request =>
        {
            payload = await request.Content!.ReadAsStringAsync();
            Assert.Equal("test-key", request.Headers.GetValues("access_token").Single());
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{\"id\":\"checkout-1\",\"link\":\"https://sandbox.asaas.com/checkoutSession/show/checkout-1\"}", Encoding.UTF8, "application/json")
            };
        });
        var settings = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Asaas:ApiKey"] = "test-key",
            ["Asaas:Environment"] = "Sandbox",
            ["PublicBaseUrl"] = "https://example.com"
        }).Build();
        var gateway = new AsaasPaymentGateway(new HttpClient(handler), settings, NullLogger<AsaasPaymentGateway>.Instance);
        var order = new GiftOrder { Id = Guid.NewGuid(), TotalCents = 2500 };
        order.Items.Add(new GiftOrderItem { GiftNameSnapshot = "Presente", Quantity = 2, PriceCentsSnapshot = 1250 });
        var response = await gateway.CreateCheckoutAsync(new PaymentAttempt { Id = Guid.NewGuid() }, order, "secret-token");
        Assert.Equal("https://sandbox.asaas.com/checkoutSession/show/checkout-1", response.CheckoutUrl);
        using var json = JsonDocument.Parse(payload!);
        Assert.Equal("DETACHED", json.RootElement.GetProperty("chargeTypes")[0].GetString());
        Assert.Equal(2, json.RootElement.GetProperty("items")[0].GetProperty("quantity").GetInt32());
        Assert.Contains("#token=secret-token", json.RootElement.GetProperty("callback").GetProperty("successUrl").GetString());
    }

    private sealed class StubHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> send) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) => send(request);
    }
}
