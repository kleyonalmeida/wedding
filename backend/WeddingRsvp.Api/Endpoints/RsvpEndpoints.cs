using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Filters;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Api.Endpoints;

public static class RsvpEndpoints
{
    public static IEndpointRouteBuilder MapRsvpEndpoints(this IEndpointRouteBuilder app, string rateLimitPolicy)
    {
        var group = app.MapGroup("/api/rsvp")
            .WithTags("RSVP")
            .WithOpenApi();

        // ── POST /api/rsvp ────────────────────────────────────────────────────
        // Recebe confirmação de presença do convidado.
        // O ValidationFilter intercepta ANTES do handler e rejeita payloads inválidos.
        group.MapPost("/", async (RsvpRequest request, AppDbContext db) =>
        {
            // Verifica duplicata de e-mail (query parametrizada — sem risco de SQL injection)
            var jaExiste = await db.Rsvps
                .AnyAsync(r => r.Email == request.Email.Trim().ToLowerInvariant());

            if (jaExiste)
            {
                return Results.Conflict(new
                {
                    message = "Este e-mail já realizou a confirmação de presença."
                });
            }

            var rsvp = new Rsvp
            {
                Id          = Guid.NewGuid(),
                Nome        = request.Nome.Trim(),
                // Normaliza o email para minúsculas para evitar duplicatas case-insensitive
                Email       = request.Email.Trim().ToLowerInvariant(),
                Telefone    = request.Telefone.Trim(),
                VaiComparecer = request.VaiComparecer,
                QtdAdultos  = request.QtdAdultos,
                QtdCriancas = request.QtdCriancas,
                // Remove espaços extras das observações (se fornecidas)
                Observacoes = request.Observacoes?.Trim(),
                // Timestamp gerado no servidor — o cliente não tem controle sobre isso
                CriadoEm   = DateTimeOffset.UtcNow
            };

            db.Rsvps.Add(rsvp);
            await db.SaveChangesAsync();

            return Results.Created($"/api/rsvp/{rsvp.Id}", new { id = rsvp.Id });
        })
        // ValidationFilter executa ANTES do handler — rejeita com 400 se inválido
        .AddEndpointFilter<ValidationFilter<RsvpRequest>>()
        .RequireRateLimiting(rateLimitPolicy)
        .WithName("CreateRsvp")
        .WithSummary("Submete confirmação de presença")
        .Produces<object>(StatusCodes.Status201Created)
        .Produces<object>(StatusCodes.Status400BadRequest)
        .Produces<object>(StatusCodes.Status409Conflict)
        .Produces(StatusCodes.Status429TooManyRequests);

        return app;
    }
}
