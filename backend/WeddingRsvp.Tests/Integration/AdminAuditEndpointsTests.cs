using System.Net;
using System.Net.Http.Json;
using Xunit;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Tests.Integration;

public class AdminAuditEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminAuditEndpointsTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private async Task<HttpClient> GetAuthenticatedClientAsync()
    {
        var client = _factory.CreateClient();
        var request = new AdminLoginRequest("admin@wedding.com", "Admin@123!");
        var response = await client.PostAsJsonAsync("/api/admin/auth/login", request);
        
        var cookies = response.Headers.GetValues("Set-Cookie");
        var authCookie = cookies.FirstOrDefault(c => c.StartsWith(".Wedding.Admin"));
        if (authCookie != null)
        {
            client.DefaultRequestHeaders.Add("Cookie", authCookie.Split(';')[0]);
        }
        
        return client;
    }

    [Fact]
    public async Task GET_AuditLogs_Unauthenticated_Returns401()
    {
        var response = await _client.GetAsync("/api/admin/audit-logs");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GET_AuditLogs_Authenticated_ReturnsOk()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.GetAsync("/api/admin/audit-logs");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.True(json.TryGetProperty("data", out var data));
        Assert.Equal(System.Text.Json.JsonValueKind.Array, data.ValueKind);
    }
}
