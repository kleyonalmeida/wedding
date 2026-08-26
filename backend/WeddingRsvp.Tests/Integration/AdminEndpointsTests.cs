using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using Microsoft.Extensions.Configuration;
using WeddingRsvp.Api.Models;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class AdminEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminEndpointsTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task POST_Login_CredenciaisCorretas_Retorna200ComToken()
    {
        // Pega as credenciais corretas da configuração usada no teste
        var config = _factory.Services.GetService(typeof(IConfiguration)) as IConfiguration;
        var username = config?["Admin:Username"] ?? "admin";
        var password = "senha_teste";

        var request = new AdminLoginRequest(username, password);
        var response = await _client.PostAsJsonAsync("/api/admin/login", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.True(json.TryGetProperty("token", out _));
    }

    [Fact]
    public async Task POST_Login_SenhaErrada_Retorna401()
    {
        var config = _factory.Services.GetService(typeof(IConfiguration)) as IConfiguration;
        var username = config?["Admin:Username"] ?? "admin";
        
        var request = new AdminLoginRequest(username, "senha_errada");
        var response = await _client.PostAsJsonAsync("/api/admin/login", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GET_Rsvps_SemToken_Retorna401()
    {
        var response = await _client.GetAsync("/api/admin/rsvps");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GET_Rsvps_ComToken_Retorna200()
    {
        // 1. Faz login para pegar token
        var config = _factory.Services.GetService(typeof(IConfiguration)) as IConfiguration;
        var username = config?["Admin:Username"] ?? "admin";
        var password = "senha_teste";
        
        var loginResponse = await _client.PostAsJsonAsync("/api/admin/login", new AdminLoginRequest(username, password));
        var json = await loginResponse.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var token = json.GetProperty("token").GetString();

        // 2. Chama endpoint protegido
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var response = await _client.GetAsync("/api/admin/rsvps");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
