using Microsoft.Extensions.Configuration;
using WeddingRsvp.Api.Payments;
using Xunit;

namespace WeddingRsvp.Tests.Unit;

public class AsaasConfigurationValidatorTests
{
    private static IConfiguration Settings(string environment = "Production", string apiKey = "$aact_prod_test") =>
        new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Asaas:Environment"] = environment,
            ["Asaas:ApiKey"] = apiKey,
            ["Asaas:WebhookAuthToken"] = new string('x', 40),
            ["PublicBaseUrl"] = "https://kleyoneliandra.com.br",
            ["AllowedOrigin"] = "https://kleyoneliandra.com.br"
        }).Build();

    [Fact]
    public void Production_WithValidConfiguration_Passes() =>
        AsaasConfigurationValidator.Validate(Settings());

    [Fact]
    public void Production_WithSandboxKey_Fails() =>
        Assert.Throws<InvalidOperationException>(() =>
            AsaasConfigurationValidator.Validate(Settings(apiKey: "$aact_hmlg_test")));

    [Fact]
    public void Production_WithUnknownKey_Fails() =>
        Assert.Throws<InvalidOperationException>(() =>
            AsaasConfigurationValidator.Validate(Settings(apiKey: "test-key")));

    [Fact]
    public void Production_WithLocalPublicUrl_Fails()
    {
        var settings = (IConfigurationRoot)Settings();
        settings["PublicBaseUrl"] = "http://localhost:8080";
        Assert.Throws<InvalidOperationException>(() => AsaasConfigurationValidator.Validate(settings));
    }

    [Fact]
    public void Production_WithInvalidWebhookToken_Fails()
    {
        var settings = (IConfigurationRoot)Settings();
        settings["Asaas:WebhookAuthToken"] = "short";
        Assert.Throws<InvalidOperationException>(() => AsaasConfigurationValidator.Validate(settings));
    }

    [Fact]
    public void Sandbox_WithTestSettings_Passes() =>
        AsaasConfigurationValidator.Validate(Settings("Sandbox", "test-key"));

    [Fact]
    public void MisspelledEnvironment_Fails() =>
        Assert.Throws<InvalidOperationException>(() =>
            AsaasConfigurationValidator.Validate(Settings("Producao")));
}
