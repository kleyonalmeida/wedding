using System;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Payments;

public class AsaasPaymentGateway : IPaymentGateway
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AsaasPaymentGateway> _logger;
    private readonly string _publicBaseUrl;

    public AsaasPaymentGateway(HttpClient httpClient, IConfiguration configuration, ILogger<AsaasPaymentGateway> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _publicBaseUrl = configuration["PublicBaseUrl"]?.TrimEnd('/') ?? string.Empty;

        var env = configuration["Asaas:Environment"] ?? "Sandbox";
        var baseUrl = env == "Production" ? "https://api.asaas.com/v3/" : "https://api-sandbox.asaas.com/v3/";
        _httpClient.BaseAddress = new Uri(baseUrl);
        
        var apiKey = configuration["Asaas:ApiKey"];
        if (string.IsNullOrEmpty(apiKey) && configuration["ASPNETCORE_ENVIRONMENT"] != "Testing")
            throw new InvalidOperationException("Asaas:ApiKey não configurada.");
        if (!string.IsNullOrEmpty(apiKey)) _httpClient.DefaultRequestHeaders.Add("access_token", apiKey);
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "WeddingRsvp-Integration/1.0");
    }

    public async Task<GatewayCheckoutResponse> CreateCheckoutAsync(PaymentAttempt attempt, GiftOrder order, string accessToken, CancellationToken cancellationToken = default)
    {
        if (!Uri.TryCreate(_publicBaseUrl, UriKind.Absolute, out var publicUri) || publicUri.Scheme != Uri.UriSchemeHttps)
            throw new InvalidOperationException("PublicBaseUrl HTTPS é obrigatória para checkout.");
        var returnUrl = $"{_publicBaseUrl}/pagamento/retorno?id={order.Id}#token={Uri.EscapeDataString(accessToken)}";
        var payload = new
        {
            chargeTypes = new[] { "DETACHED" },
            billingTypes = new[] { "PIX", "CREDIT_CARD" },
            minutesToExpire = 60,
            items = order.Items.Select(i => new { name = i.GiftNameSnapshot, quantity = i.Quantity, value = i.PriceCentsSnapshot / 100m }).ToArray(),
            callback = new { successUrl = returnUrl, cancelUrl = returnUrl, expiredUrl = returnUrl },
            externalReference = attempt.Id.ToString()
        };

        _logger.LogInformation("Creating checkout for attempt {AttemptId}", attempt.Id);
        
        var response = await _httpClient.PostAsJsonAsync("checkouts", payload, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogError("Asaas checkout creation failed: {StatusCode} - {Error}", response.StatusCode, errorContent);
            throw new Exception($"Failed to create Asaas checkout: {response.StatusCode}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
        var checkoutId = result.GetProperty("id").GetString();
        if (string.IsNullOrWhiteSpace(checkoutId)) throw new InvalidOperationException("Asaas did not return checkout id.");
        var checkoutUrl = result.TryGetProperty("link", out var link) && link.ValueKind == JsonValueKind.String
            ? link.GetString()
            : $"https://asaas.com/checkoutSession/show?id={Uri.EscapeDataString(checkoutId)}";
        if (!Uri.TryCreate(checkoutUrl, UriKind.Absolute, out var checkoutUri) || checkoutUri.Scheme != Uri.UriSchemeHttps ||
            !(checkoutUri.Host == "asaas.com" || checkoutUri.Host.EndsWith(".asaas.com", StringComparison.OrdinalIgnoreCase)))
            throw new InvalidOperationException("Asaas returned an invalid checkout URL.");

        return new GatewayCheckoutResponse(checkoutId, checkoutUrl);
    }

    public async Task<GatewayPaymentResponse> GetPaymentStatusAsync(string gatewayPaymentId, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"payments/{gatewayPaymentId}", cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new Exception($"Failed to get payment from Asaas: {response.StatusCode}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
        var status = result.GetProperty("status").GetString();
        var netValue = result.GetProperty("netValue").GetDecimal();
        var billingType = result.GetProperty("billingType").GetString();

        return new GatewayPaymentResponse(status!, (long)(netValue * 100), billingType!);
    }
}
