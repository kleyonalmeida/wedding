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
            .RequireRateLimiting(rateLimitPolicy);

        // ── GET /api/admin/rsvps ──────────────────────────────────────────────
        // Lista todos os RSVPs com resumo estatístico.
        // Protegido por Cookie (Policy SuperAdmin)
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
        .RequireAuthorization("SuperAdmin")
        .WithName("ListRsvps")
        .WithSummary("Lista todos os RSVPs (admin)")
        .Produces<object>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status401Unauthorized);

        return app;
    }
}
