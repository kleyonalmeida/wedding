using System.Net;
using System.Net.Http.Json;
using WeddingRsvp.Api.Models;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class AdminDashboardEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminDashboardEndpointsTests(CustomWebApplicationFactory factory)
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
    public async Task GET_DashboardSummary_Authenticated_ReturnsOk()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.GetAsync("/api/admin/dashboard/summary");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GET_DashboardActivity_Authenticated_ReturnsOk()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.GetAsync("/api/admin/dashboard/activity?limit=5");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
