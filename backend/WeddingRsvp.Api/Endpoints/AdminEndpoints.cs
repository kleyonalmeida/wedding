using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminEndpoints
{
    public static IEndpointRouteBuilder MapAdminEndpoints(this IEndpointRouteBuilder app, string rateLimitPolicy)
    {
        var group = app.MapGroup("/api/admin")
            .WithTags("Admin")
            .WithOpenApi()
            .RequireRateLimiting(rateLimitPolicy);

        // ── POST /api/admin/login ─────────────────────────────────────────────
        // Autentica o administrador e retorna um JWT com validade de 8h.
        // BCrypt.Verify usa comparação de tempo constante — resistente a timing attacks.
        group.MapPost("/login", (AdminLoginRequest request, IConfiguration config) =>
        {
            var expectedUsername = config["Admin:Username"];
            var expectedPasswordHash = config["Admin:PasswordHash"];
            var jwtSecret = config["Jwt:Secret"]!;
            var jwtIssuer = config["Jwt:Issuer"]!;

            // Valida credenciais — ambas as verificações ocorrem sempre (sem short-circuit)
            // para evitar que um atacante determine o username correto por timing
            bool usernameOk = string.Equals(request.Username, expectedUsername, StringComparison.Ordinal);
            bool passwordOk = !string.IsNullOrEmpty(expectedPasswordHash)
                              && BCrypt.Net.BCrypt.Verify(request.Password, expectedPasswordHash);

            if (!usernameOk || !passwordOk)
            {
                // Resposta genérica — não revela qual campo está errado
                return Results.Unauthorized();
            }

            var token = GenerateJwtToken(jwtSecret, jwtIssuer);

            return Results.Ok(new
            {
                token,
                expiresAt = DateTime.UtcNow.AddHours(8)
            });
        })
        .AllowAnonymous()
        .WithName("AdminLogin")
        .WithSummary("Autentica o administrador e retorna token JWT")
        .Produces<object>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status401Unauthorized);

        // ── GET /api/admin/rsvps ──────────────────────────────────────────────
        // Lista todos os RSVPs com resumo estatístico.
        // Protegido por JWT — exige header: Authorization: Bearer <token>
        group.MapGet("/rsvps", async (AppDbContext db) =>
        {
            var rsvps = await db.Rsvps
                .OrderByDescending(r => r.CriadoEm)
                .Select(r => new
                {
                    r.Id,
                    r.Nome,
                    r.Email,
                    r.Telefone,
                    r.VaiComparecer,
                    r.QtdAdultos,
                    r.QtdCriancas,
                    r.Observacoes,
                    r.CriadoEm
                })
                .AsNoTracking() // Read-only — evita overhead de change tracking
                .ToListAsync();

            var confirmados  = rsvps.Where(r => r.VaiComparecer).ToList();
            var naoVao       = rsvps.Where(r => !r.VaiComparecer).ToList();
            var totalAdultos = confirmados.Sum(r => r.QtdAdultos);
            var totalCriancas = confirmados.Sum(r => r.QtdCriancas);

            return Results.Ok(new
            {
                resumo = new
                {
                    totalRespostas = rsvps.Count,
                    confirmados    = confirmados.Count,
                    naoVao         = naoVao.Count,
                    totalAdultos,
                    totalCriancas,
                    totalPessoas   = totalAdultos + totalCriancas
                },
                rsvps
            });
        })
        .RequireAuthorization()
        .WithName("ListRsvps")
        .WithSummary("Lista todos os RSVPs (admin)")
        .Produces<object>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status401Unauthorized);

        return app;
    }

    /// <summary>
    /// Gera um token JWT assinado com HMAC-SHA256.
    /// Validade de 8 horas — suficiente para uma sessão de trabalho do admin.
    /// </summary>
    private static string GenerateJwtToken(string secret, string issuer)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.Role, "Admin"),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer:             issuer,
            audience:           issuer,
            claims:             claims,
            notBefore:          DateTime.UtcNow,
            expires:            DateTime.UtcNow.AddHours(8),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
