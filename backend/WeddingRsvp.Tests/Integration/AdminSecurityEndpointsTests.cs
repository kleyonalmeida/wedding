using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using WeddingRsvp.Api.Models;
using Xunit;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Identity;
using WeddingRsvp.Api.Entities;
using System.Buffers.Binary;
using System.Security.Cryptography;

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
    public async Task MfaEnrollmentPreservesSessionUntilConfirmationThenRequiresTotpAtNextLogin()
    {
        using var factory = new CustomWebApplicationFactory();
        using var client = factory.CreateClient();

        var login = await client.PostAsJsonAsync("/api/admin/auth/login",
            new AdminLoginRequest("admin@wedding.com", "Admin@123!"));
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        SetCookie(client, login, ".Wedding.Admin");
        await CustomWebApplicationFactory.AddCsrfAsync(client);

        var enroll = await client.PostAsync("/api/admin/security/mfa/enroll", null);
        Assert.Equal(HttpStatusCode.OK, enroll.StatusCode);
        var enrollment = await enroll.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var sharedKey = enrollment.GetProperty("sharedKey").GetString()!;
        SetCookie(client, enroll, ".Wedding.Admin");
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/admin/auth/me")).StatusCode);

        var totp = CurrentTotp(sharedKey);

        var confirm = await client.PostAsJsonAsync("/api/admin/security/mfa/confirm", new { code = totp });
        Assert.Equal(HttpStatusCode.OK, confirm.StatusCode);
        Assert.Contains(confirm.Headers.GetValues("Set-Cookie"),
            c => c.StartsWith(".Wedding.Admin=") && c.Contains("expires=", StringComparison.OrdinalIgnoreCase));
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/admin/auth/me")).StatusCode);

        using var nextClient = factory.CreateClient();
        var nextLogin = await nextClient.PostAsJsonAsync("/api/admin/auth/login",
            new AdminLoginRequest("admin@wedding.com", "Admin@123!"));
        Assert.Equal(HttpStatusCode.OK, nextLogin.StatusCode);
        var nextLoginBody = await nextLogin.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.True(nextLoginBody.GetProperty("requiresTwoFactor").GetBoolean());
        SetCookie(nextClient, nextLogin, "TwoFactorUserId");
        var verify = await nextClient.PostAsJsonAsync("/api/admin/auth/mfa/verify",
            new { code = CurrentTotp(sharedKey) });
        Assert.Equal(HttpStatusCode.OK, verify.StatusCode);
        SetCookie(nextClient, verify, ".Wedding.Admin");
        Assert.Equal(HttpStatusCode.OK, (await nextClient.GetAsync("/api/admin/auth/me")).StatusCode);
    }

    private static void SetCookie(HttpClient client, HttpResponseMessage response, string cookieName)
    {
        var cookie = response.Headers.GetValues("Set-Cookie")
            .First(c => c.Split('=')[0].EndsWith(cookieName, StringComparison.Ordinal));
        var actualName = cookie.Split('=')[0];
        var others = client.DefaultRequestHeaders.TryGetValues("Cookie", out var existing)
            ? existing.Single().Split("; ", StringSplitOptions.RemoveEmptyEntries)
                .Where(c => !c.StartsWith(actualName + "=", StringComparison.Ordinal))
            : Enumerable.Empty<string>();
        client.DefaultRequestHeaders.Remove("Cookie");
        client.DefaultRequestHeaders.Add("Cookie", string.Join("; ", others.Append(cookie.Split(';')[0])));
    }

    private static string CurrentTotp(string base32Secret)
    {
        var bytes = new List<byte>();
        var bits = 0;
        var buffer = 0;
        foreach (var character in base32Secret.ToUpperInvariant().TrimEnd('='))
        {
            buffer = (buffer << 5) | "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".IndexOf(character);
            bits += 5;
            if (bits >= 8)
            {
                bits -= 8;
                bytes.Add((byte)(buffer >> bits));
            }
        }
        Span<byte> counter = stackalloc byte[8];
        BinaryPrimitives.WriteInt64BigEndian(counter, DateTimeOffset.UtcNow.ToUnixTimeSeconds() / 30);
        var hash = HMACSHA1.HashData(bytes.ToArray(), counter);
        var offset = hash[^1] & 0x0f;
        var value = BinaryPrimitives.ReadInt32BigEndian(hash.AsSpan(offset, 4)) & 0x7fffffff;
        return (value % 1_000_000).ToString("D6");
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
