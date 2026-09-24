using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using WeddingRsvp.Api.Models;
using Xunit;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Identity;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Tests.Integration;

public class AdminSecurityEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminSecurityEndpointsTests(CustomWebApplicationFactory factory)
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
        
        await CustomWebApplicationFactory.AddCsrfAsync(client);
        return client;
    }

    [Fact]
    public async Task POST_MfaEnroll_Unauthenticated_Returns401()
    {
        var response = await _client.PostAsync("/api/admin/security/mfa/enroll", null);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task POST_MfaEnroll_Authenticated_ReturnsSharedKey()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.PostAsync("/api/admin/security/mfa/enroll", null);
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        
        Assert.True(json.TryGetProperty("sharedKey", out _));
        Assert.True(json.TryGetProperty("authenticatorUri", out _));
    }

    [Fact]
    public async Task POST_ChangePassword_InvalidCurrentPassword_Returns400()
    {
        var client = await GetAuthenticatedClientAsync();
        var request = new { currentPassword = "WrongPassword", newPassword = "NewStrongPassword123!" };
        var response = await client.PostAsJsonAsync("/api/admin/security/password", request);
        
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_RevokeSessions_ReturnsOk()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.PostAsync("/api/admin/security/sessions/revoke", null);
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
