using System.Net;
using System.Net.Http.Json;
using WeddingRsvp.Api.Models;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class AdminAttendanceEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminAttendanceEndpointsTests(CustomWebApplicationFactory factory)
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
    public async Task GET_Attendance_Unauthenticated_Returns401()
    {
        var response = await _client.GetAsync("/api/admin/attendance");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GET_Attendance_Authenticated_ReturnsOk()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.GetAsync("/api/admin/attendance");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
    
    [Fact]
    public async Task PATCH_Attendance_ValidUpdate_UpdatesAndAudits()
    {
        var client = await GetAuthenticatedClientAsync();
        
        // 1. Create a dummy RSVP
        var rsvpRequest = new RsvpRequest("Test Update", "update@test.com", "11999999999", true, 2, 0, null);
        await client.PostAsJsonAsync("/api/rsvp", rsvpRequest);
        
        // 2. Fetch the RSVP list to get its ID
        var listResponse = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/admin/attendance?search=update@test.com");
        var items = listResponse.GetProperty("data").EnumerateArray().ToList();
        Assert.Single(items);
        var id = items[0].GetProperty("id").GetGuid();
        
        // 3. Patch it
        var patchResponse = await client.PatchAsJsonAsync($"/api/admin/attendance/{id}", new { vaiComparecer = false, motivo = "Manual override" });
        Assert.Equal(HttpStatusCode.OK, patchResponse.StatusCode);
        
        // 4. Verify it was updated
        var getResponse = await client.GetFromJsonAsync<System.Text.Json.JsonElement>($"/api/admin/attendance/{id}");
        Assert.False(getResponse.GetProperty("vaiComparecer").GetBoolean());
    }
}
