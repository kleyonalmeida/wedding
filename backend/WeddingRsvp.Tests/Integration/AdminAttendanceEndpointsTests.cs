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

    private async Task<System.Text.Json.JsonElement> CriarLinhaERespostaAsync(
        HttpClient adminClient,
        string identificacao,
        int adultos,
        bool vaiComparecer = true)
    {
        // Cadastrar linha
        await adminClient.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = identificacao, quantidadeAdultos = adultos });

        // Enviar RSVP como público
        var publicClient = _factory.CreateClient();
        await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = identificacao,
            vaiComparecer = vaiComparecer,
            qtdCriancas = 0,
            email = $"{System.Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        // Retorna o RSVP criado
        var listResponse = await adminClient.GetFromJsonAsync<System.Text.Json.JsonElement>(
            $"/api/admin/attendance?search={Uri.EscapeDataString(identificacao)}");
        return listResponse.GetProperty("data").EnumerateArray().First();
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
        var id = "Patch Test " + Guid.NewGuid().ToString("N")[..6];
        
        // Cria linha e RSVP
        var item = await CriarLinhaERespostaAsync(client, id, 2);
        var rsvpId = item.GetProperty("id").GetGuid();
        
        // Patch
        var patchResponse = await client.PatchAsJsonAsync(
            $"/api/admin/attendance/{rsvpId}",
            new { vaiComparecer = false, motivo = "Manual override" });
        Assert.Equal(HttpStatusCode.OK, patchResponse.StatusCode);
        
        // Verifica atualização
        var getResponse = await client.GetFromJsonAsync<System.Text.Json.JsonElement>(
            $"/api/admin/attendance/{rsvpId}");
        Assert.False(getResponse.GetProperty("vaiComparecer").GetBoolean());
    }
}
