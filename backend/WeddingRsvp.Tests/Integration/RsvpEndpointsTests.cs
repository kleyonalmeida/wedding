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

public class RsvpEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public RsvpEndpointsTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task POST_Valido_Retorna201()
    {
        var request = new RsvpRequest(
            "Convidado Teste", "convidado1@teste.com", "(11) 91234-5678", true, 2, 0, null);

        var response = await _client.PostAsJsonAsync("/api/rsvp", request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_EmailDuplicado_Retorna409()
    {
        var request = new RsvpRequest(
            "Convidado Duplicado", "duplicado@teste.com", "11987654321", true, 2, 0, null);

        // Primeiro envio
        await _client.PostAsJsonAsync("/api/rsvp", request);

        // Segundo envio com o mesmo e-mail
        var response2 = await _client.PostAsJsonAsync("/api/rsvp", request);

        Assert.Equal(HttpStatusCode.Conflict, response2.StatusCode);
    }

    [Fact]
    public async Task POST_NomeVazio_Retorna400()
    {
        var request = new RsvpRequest(
            "", "invalido1@teste.com", "11987654321", true, 2, 0, null);

        var response = await _client.PostAsJsonAsync("/api/rsvp", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_EmailInvalido_Retorna400()
    {
        var request = new RsvpRequest(
            "Convidado", "emailinvalido", "11987654321", true, 2, 0, null);

        var response = await _client.PostAsJsonAsync("/api/rsvp", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_PayloadSql_Retorna400()
    {
        var request = new RsvpRequest(
            "1' OR '1'='1", "sql@teste.com", "11987654321", true, 2, 0, null);

        var response = await _client.PostAsJsonAsync("/api/rsvp", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_RecusaComZeroPessoas_Retorna201()
    {
        var request = new RsvpRequest("Convidado Recusou", "recusou@teste.com", "11987654321", false, 0, 0, null);
        var response = await _client.PostAsJsonAsync("/api/rsvp", request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_QtdAdultosZero_Retorna400()
    {
        var request = new RsvpRequest(
            "Convidado", "adultozero@teste.com", "11987654321", true, 0, 0, null);

        var response = await _client.PostAsJsonAsync("/api/rsvp", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
