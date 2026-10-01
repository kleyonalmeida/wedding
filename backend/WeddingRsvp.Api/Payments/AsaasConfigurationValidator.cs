using Microsoft.Extensions.Configuration;

namespace WeddingRsvp.Api.Payments;

public static class AsaasConfigurationValidator
{
    public static void Validate(IConfiguration configuration)
    {
        var environment = configuration["Asaas:Environment"] ?? "Sandbox";
        if (environment is not ("Sandbox" or "Production"))
            throw new InvalidOperationException("Asaas:Environment deve ser Sandbox ou Production.");

        if (environment != "Production") return;

        var apiKey = configuration["Asaas:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey) || !apiKey.StartsWith("$aact_prod_", StringComparison.Ordinal))
            throw new InvalidOperationException("Asaas de produção requer uma chave de API de produção com prefixo atual.");

        var webhookToken = configuration["Asaas:WebhookAuthToken"];
        if (string.IsNullOrWhiteSpace(webhookToken) || webhookToken.Length is < 32 or > 255 ||
            webhookToken.Any(char.IsWhiteSpace) || webhookToken == apiKey)
            throw new InvalidOperationException("Asaas de produção requer um token de webhook próprio de 32 a 255 caracteres.");

        if (!IsPublicHttpsUrl(configuration["PublicBaseUrl"]))
            throw new InvalidOperationException("PublicBaseUrl deve ser uma URL HTTPS pública em produção.");

        if (!IsPublicHttpsUrl(configuration["AllowedOrigin"]))
            throw new InvalidOperationException("AllowedOrigin deve ser uma origem HTTPS pública em produção.");
    }

    private static bool IsPublicHttpsUrl(string? value) =>
        Uri.TryCreate(value, UriKind.Absolute, out var uri) &&
        uri.Scheme == Uri.UriSchemeHttps && !uri.IsLoopback &&
        !uri.Host.Contains("SEU_DOMINIO", StringComparison.OrdinalIgnoreCase);
}
