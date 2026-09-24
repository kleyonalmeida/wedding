using System.Net;
using System.Net.Http.Json;
using WeddingRsvp.Api.Models;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class AdminAuthEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminAuthEndpointsTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task POST_Login_InvalidUser_Returns401()
    {
        var request = new AdminLoginRequest("invalid@wedding.com", "WrongPassword1!");
        var response = await _client.PostAsJsonAsync("/api/admin/auth/login", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task POST_Login_ValidCredentials_ReturnsOk()
    {
        var request = new AdminLoginRequest("admin@wedding.com", "Admin@123!");
        var response = await _client.PostAsJsonAsync("/api/admin/auth/login", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        // Assert cookies
        Assert.Contains(response.Headers.GetValues("Set-Cookie"), c => c.StartsWith(".Wedding.Admin"));
    }
}
