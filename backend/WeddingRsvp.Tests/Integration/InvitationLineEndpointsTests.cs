using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using WeddingRsvp.Api.Models;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

[CollectionDefinition("InvitationLine")]
public class InvitationLineCollection : ICollectionFixture<CustomWebApplicationFactory> { }

/// <summary>
/// Testes de integração para endpoints de linhas de convite (Admin).
/// Seguem TDD: escritos antes da implementação — devem FALHAR inicialmente.
/// </summary>
[Collection("InvitationLine")]
public class InvitationLineAdminEndpointsTests
{
    private readonly CustomWebApplicationFactory _factory;

    public InvitationLineAdminEndpointsTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<HttpClient> GetAuthenticatedClientAsync()
    {
        var client = _factory.CreateClient();
        var loginRequest = new AdminLoginRequest("admin@wedding.com", "Admin@123!");
        var loginResponse = await client.PostAsJsonAsync("/api/admin/auth/login", loginRequest);

        if (!loginResponse.IsSuccessStatusCode)
            throw new InvalidOperationException($"Login falhou com status {loginResponse.StatusCode}");

        if (!loginResponse.Headers.TryGetValues("Set-Cookie", out var cookies))
            throw new InvalidOperationException("Resposta de login não contém Set-Cookie.");

        var authCookie = cookies.FirstOrDefault(c => c.StartsWith(".Wedding.Admin"));
        if (authCookie != null)
            client.DefaultRequestHeaders.Add("Cookie", authCookie.Split(';')[0]);

        await CustomWebApplicationFactory.AddCsrfAsync(client);
        return client;
    }

    // ── Cadastro ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task POST_InvitationLine_UnauthenticatedRetorna401()
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = "Jorge e Amanda", quantidadeAdultos = 2 });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task POST_InvitationLine_ValidaIdentificacaoEAdultos_Retorna201()
    {
        var client = await GetAuthenticatedClientAsync();
        var id = "Jorge e Amanda " + Guid.NewGuid().ToString("N");
        var response = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = id, quantidadeAdultos = 2 });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(id, body.GetProperty("identificacaoNoConvite").GetString());
        Assert.Equal(2, body.GetProperty("quantidadeAdultos").GetInt32());
        Assert.True(body.GetProperty("ativo").GetBoolean());
    }

    [Fact]
    public async Task POST_InvitationLine_ZeroAdultos_Retorna400()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = "Zero Adultos", quantidadeAdultos = 0 });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_InvitationLine_IdentificacaoVazia_Retorna400()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = "", quantidadeAdultos = 2 });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_InvitationLine_DuplicadaAtiva_Retorna409()
    {
        var client = await GetAuthenticatedClientAsync();
        var id1 = "Carla e Roberto " + Guid.NewGuid().ToString("N")[..6];

        await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = id1, quantidadeAdultos = 2 });

        // Mesma identificação normalizada → conflito
        var response2 = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = id1, quantidadeAdultos = 2 });

        Assert.Equal(HttpStatusCode.Conflict, response2.StatusCode);
    }

    [Fact]
    public async Task POST_InvitationLine_ComAcentos_DeveSerAceita()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = "Antônio e Luís", quantidadeAdultos = 2 });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    // ── Listagem ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task GET_InvitationLines_RetornaListaPaginada()
    {
        var client = await GetAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/admin/invitation-lines");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("data", out _));
        Assert.True(body.TryGetProperty("total", out _));
    }

    // ── Edição ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task PUT_InvitationLine_AlteraQuantidadeAdultos()
    {
        var client = await GetAuthenticatedClientAsync();

        // Cadastrar
        var createResponse = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = "Beatriz Ferreira " + Guid.NewGuid().ToString("N")[..6], quantidadeAdultos = 1 });
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var id = created.GetProperty("id").GetGuid();

        // Editar
        var putResponse = await client.PutAsJsonAsync($"/api/admin/invitation-lines/{id}",
            new { quantidadeAdultos = 3, ativo = true, motivo = "Correção de cadastro" });

        Assert.Equal(HttpStatusCode.OK, putResponse.StatusCode);

        var updated = await putResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(3, updated.GetProperty("quantidadeAdultos").GetInt32());
    }

    [Fact]
    public async Task DELETE_InvitationLine_Desativa()
    {
        var client = await GetAuthenticatedClientAsync();

        // Cadastrar
        var createResponse = await client.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = "Desativar Teste " + Guid.NewGuid().ToString("N")[..6], quantidadeAdultos = 1 });
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var id = created.GetProperty("id").GetGuid();

        // Desativar
        var deleteResponse = await client.DeleteAsync($"/api/admin/invitation-lines/{id}");
        Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);

        // Verificar que está inativo
        var getResponse = await client.GetFromJsonAsync<JsonElement>($"/api/admin/invitation-lines/{id}");
        Assert.False(getResponse.GetProperty("ativo").GetBoolean());
    }
}

/// <summary>
/// Testes de integração para POST /api/rsvp com validação por linha de convite.
/// Escritos antes da implementação — devem FALHAR inicialmente.
/// </summary>
[Collection("InvitationLine")]
public class RsvpEndpointsWithInvitationLineTests
{
    private readonly CustomWebApplicationFactory _factory;

    public RsvpEndpointsWithInvitationLineTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<HttpClient> GetAuthenticatedClientAsync()
    {
        var client = _factory.CreateClient();
        var loginRequest = new AdminLoginRequest("admin@wedding.com", "Admin@123!");
        var loginResponse = await client.PostAsJsonAsync("/api/admin/auth/login", loginRequest);

        if (!loginResponse.IsSuccessStatusCode)
            throw new InvalidOperationException($"Login falhou com status {loginResponse.StatusCode}");

        if (!loginResponse.Headers.TryGetValues("Set-Cookie", out var cookies))
            throw new InvalidOperationException("Resposta de login não contém Set-Cookie.");

        var authCookie = cookies.FirstOrDefault(c => c.StartsWith(".Wedding.Admin"));
        if (authCookie != null)
            client.DefaultRequestHeaders.Add("Cookie", authCookie.Split(';')[0]);

        await CustomWebApplicationFactory.AddCsrfAsync(client);
        return client;
    }

    private async Task CriarLinha(HttpClient adminClient, string identificacao, int adultos)
    {
        var response = await adminClient.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = identificacao, quantidadeAdultos = adultos });
        response.EnsureSuccessStatusCode();
    }

    // ── Confirmação com linha cadastrada ──────────────────────────────────────

    [Fact]
    public async Task POST_Rsvp_IdentificacaoExata_JorgeEAmanda_Retorna201()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        await CriarLinha(adminClient, "Jorge e Amanda", 2);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = "Jorge e Amanda",
            vaiComparecer = true,
            qtdCriancas = 0,
            email = "jorgeamanda@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_Rsvp_AceitaMaiusculasDiferentesEConservaGrafiaCadastrada()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var identificacao = "Jorge e Amanda " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, identificacao, 2);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = identificacao.ToLowerInvariant(),
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<JsonElement>();
        var saved = await adminClient.GetFromJsonAsync<JsonElement>(
            $"/api/admin/attendance/{created.GetProperty("id").GetGuid()}");
        Assert.Equal(identificacao, saved.GetProperty("identificacaoNoConvite").GetString());
        Assert.Equal(2, saved.GetProperty("qtdAdultos").GetInt32());
    }

    [Fact]
    public async Task POST_Rsvp_Confirmacao_GravaAdultosDoAdmin_NaoDoCliente()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var idLine = "Casal Automático " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, idLine, 2);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = idLine,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"casal{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        // Admin verifica que qtdAdultos é 2 (do Admin), não um valor enviado pelo cliente
        var listResponse = await adminClient.GetFromJsonAsync<JsonElement>("/api/admin/attendance");
        var items = listResponse.GetProperty("data").EnumerateArray()
            .Where(i => i.GetProperty("identificacaoNoConvite").GetString() == idLine)
            .ToList();

        Assert.Single(items);
        Assert.Equal(2, items[0].GetProperty("qtdAdultos").GetInt32());
    }

    [Fact]
    public async Task POST_Rsvp_ZeroCriancas_Retorna201()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "SemCriancas " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, id, 1);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
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
    public async Task POST_Rsvp_UmaCrianca_Retorna201()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "UmaCrianca " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, id, 1);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 1,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_Rsvp_DezCriancas_Retorna201()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "DezCriancas " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, id, 1);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 10,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task POST_Rsvp_OnzeCriancas_Retorna400()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "OnzeCriancas " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, id, 1);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 11,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_Rsvp_Recusa_GravaZeroAdultosZeroCriancas()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "Recusa " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, id, 2);

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = false,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var listResponse = await adminClient.GetFromJsonAsync<JsonElement>("/api/admin/attendance");
        var items = listResponse.GetProperty("data").EnumerateArray()
            .Where(i => i.GetProperty("identificacaoNoConvite").GetString() == id)
            .ToList();

        Assert.Single(items);
        Assert.Equal(0, items[0].GetProperty("qtdAdultos").GetInt32());
        Assert.Equal(0, items[0].GetProperty("qtdCriancas").GetInt32());
    }

    // ── Identificação desconhecida / inativa ──────────────────────────────────

    [Fact]
    public async Task POST_Rsvp_IdentificacaoDesconhecida_Retorna404ComCodigoNegocio()
    {
        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = "Ninguém Registrado " + Guid.NewGuid().ToString("N"),
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("INVITATION_NOT_FOUND", body.GetProperty("code").GetString());
    }

    [Fact]
    public async Task POST_Rsvp_LinhaInativa_Retorna422ComCodigoNegocio()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "Inativa " + Guid.NewGuid().ToString("N")[..6];
        var createResponse = await adminClient.PostAsJsonAsync("/api/admin/invitation-lines",
            new { identificacaoNoConvite = id, quantidadeAdultos = 1 });
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var lineId = created.GetProperty("id").GetGuid();

        // Desativar
        await adminClient.DeleteAsync($"/api/admin/invitation-lines/{lineId}");

        var publicClient = _factory.CreateClient();
        var response = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("INVITATION_NOT_FOUND", body.GetProperty("code").GetString());
    }

    [Fact]
    public async Task POST_Rsvp_LinhaNaoExpostaNaListaPublica_ApiNaoRevela()
    {
        // Verificar que não existe endpoint público que lista linhas cadastradas
        var publicClient = _factory.CreateClient();
        var response = await publicClient.GetAsync("/api/rsvp/invitation-lines");

        // Deve retornar 404 (endpoint não existe) — não expõe lista de convidados
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ── Duplicidade por linha ─────────────────────────────────────────────────

    [Fact]
    public async Task POST_Rsvp_LinhaJaRespondida_Retorna422ComCodigoNegocio()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var id = "Duplicidade " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, id, 2);

        var publicClient = _factory.CreateClient();

        // Primeira resposta
        await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com",
            telefone = "11987654321",
            aceitouTermos = true
        });

        // Segunda resposta para a mesma linha
        var response2 = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = id,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = $"{Guid.NewGuid():N}@teste.com", // e-mail diferente!
            telefone = "11987654321",
            aceitouTermos = true
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response2.StatusCode);
        var body = await response2.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("INVITATION_ALREADY_RESPONDED", body.GetProperty("code").GetString());
    }

    [Fact]
    public async Task POST_Rsvp_EmailCompartilhadoEntreDiferentesLinhas_NaoBloqueiaSegundaLinha()
    {
        var adminClient = await GetAuthenticatedClientAsync();
        var idA = "LinhaA Compartilhada " + Guid.NewGuid().ToString("N")[..6];
        var idB = "LinhaB Compartilhada " + Guid.NewGuid().ToString("N")[..6];
        await CriarLinha(adminClient, idA, 1);
        await CriarLinha(adminClient, idB, 1);

        var email = $"compartilhado{Guid.NewGuid():N}@teste.com";
        var publicClient = _factory.CreateClient();

        // Primeira linha
        var r1 = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = idA,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = email,
            telefone = "11987654321",
            aceitouTermos = true
        });
        Assert.Equal(HttpStatusCode.Created, r1.StatusCode);

        // Segunda linha com o mesmo e-mail — deve funcionar!
        var r2 = await publicClient.PostAsJsonAsync("/api/rsvp", new
        {
            identificacaoNoConvite = idB,
            vaiComparecer = true,
            qtdCriancas = 0,
            email = email,
            telefone = "11987654321",
            aceitouTermos = true
        });
        Assert.Equal(HttpStatusCode.Created, r2.StatusCode);
    }

    // ── Totais do Admin ───────────────────────────────────────────────────────

    [Fact]
    public async Task GET_AttendanceSummary_MostraTotaisPorLinhas()
    {
        var adminClient = await GetAuthenticatedClientAsync();

        var response = await adminClient.GetFromJsonAsync<JsonElement>("/api/admin/attendance/summary");

        // Deve existir campo de linhas pendentes, confirmadas e recusadas
        Assert.True(response.TryGetProperty("linhasPendentes", out _));
        Assert.True(response.TryGetProperty("linhasConfirmadas", out _));
        Assert.True(response.TryGetProperty("linhasRecusadas", out _));
        Assert.True(response.TryGetProperty("totalAdultos", out _));
        Assert.True(response.TryGetProperty("totalCriancas", out _));
    }
}
