using System.Net;
using System.Net.Http.Json;
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
    public async Task GET_Rsvps_SemCookie_Retorna401()
    {
        var response = await _client.GetAsync("/api/admin/rsvps");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GET_Rsvps_ComCookie_Retorna200()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.GetAsync("/api/admin/rsvps");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
