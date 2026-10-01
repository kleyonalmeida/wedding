using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Models;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    public static async Task AddCsrfAsync(HttpClient client)
    {
        var response = await client.GetAsync("/api/admin/auth/csrf");
        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        client.DefaultRequestHeaders.Add("X-CSRF-TOKEN", json.GetProperty("token").GetString());
        var cookie = response.Headers.GetValues("Set-Cookie").FirstOrDefault();
        if (cookie != null)
        {
            var existing = client.DefaultRequestHeaders.GetValues("Cookie").First();
            client.DefaultRequestHeaders.Remove("Cookie");
            client.DefaultRequestHeaders.Add("Cookie", existing + "; " + cookie.Split(';')[0]);
        }
    }
    static CustomWebApplicationFactory()
    {
        Program.IsTesting = true;
    }

    public string DbName { get; } = "TestDb_" + Guid.NewGuid().ToString();

    protected override void ConfigureWebHost(Microsoft.AspNetCore.Hosting.IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
            if (descriptor != null)
            {
                services.Remove(descriptor);
            }
            services.AddDbContext<AppDbContext>(options => options.UseInMemoryDatabase(DbName));
        });
    }
}

/// <summary>
/// Testes de integração básicos do endpoint POST /api/rsvp.
/// Nota: com a nova lógica, POST /api/rsvp exige linha cadastrada previamente.
/// Testes mais completos estão em InvitationLineEndpointsTests.cs.
/// </summary>
public class RsvpEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public RsvpEndpointsTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private async Task<HttpClient> GetAuthenticatedClientAsync()
    {
        var client = _factory.CreateClient();
        var loginRequest = new AdminLoginRequest("admin@wedding.com", "Admin@123!");
        var loginResponse = await client.PostAsJsonAsync("/api/admin/auth/login", loginRequest);

        var cookies = loginResponse.Headers.GetValues("Set-Cookie");
        var authCookie = cookies.FirstOrDefault(c => c.StartsWith(".Wedding.Admin"));
        if (authCookie != null)
            client.DefaultRequestHeaders.Add("Cookie", authCookie.Split(';')[0]);

        await CustomWebApplicationFactory.AddCsrfAsync(client);
        return client;
    }

    private async Task<string> CriarLinhaAsync(HttpClient adminClient, string identificacao, int adultos)
    {
        var response = await adminClient.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = identificacao, quantidadeAdultos = adultos });
        response.EnsureSuccessStatusCode();
        return identificacao;
    }

    [Fact]
    public async Task POST_IdentificacaoDesconhecida_Retorna422()
    {
        var response = await _client.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = "Ninguem " + Guid.NewGuid().ToString("N"),
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"x{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task POST_LinhaValida_Retorna201()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "Convidado Valido " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinhaAsync(adminClient, id, 2);

        var response = await _client.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_PayloadSemAceitarTermos_Retorna400()
    {
        var response = await _client.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = "Qualquer Um",
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = false // não aceita
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_EmailInvalido_Retorna400()
    {
        var response = await _client.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = "Qualquer Um",
            vaiComparecer = true,
            qtdCriancas = 0,
            email = "emailinvalido",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_RecusaComLinhaValida_Retorna201()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "Recusa Simples " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinhaAsync(adminClient, id, 1);

        var response = await _client.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = false,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_OnzeCriancas_Retorna400()
    {
        var response = await _client.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = "Qualquer Um",
            vaiComparecer = true,
            qtdCriancas = 11, // Acima do máximo (10)
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
