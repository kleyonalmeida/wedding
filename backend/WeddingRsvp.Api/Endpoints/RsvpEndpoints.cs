using FluentValidation;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Endpoints;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Filters;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Api.Endpoints;

public static class RsvpEndpoints
{
    public static IEndpointRouteBuilder MapRsvpEndpoints(this IEndpointRouteBuilder app, string rateLimitPolicy)
    {
        var group = app.MapGroup("/api/rsvp")
            .WithTags("RSVP");

        // ── POST /api/rsvp ────────────────────────────────────────────────────
        // Recebe confirmação de presença via QR code genérico.
        // 1. Valida payload (ValidationFilter)
        // 2. Busca linha de convite cadastrada pelo Admin
        // 3. Verifica se já foi respondida
        // 4. Deriva adultos da linha (não do cliente)
        // 5. Grava RSVP
        group.MapPost("/", async (
            RsvpRequest request,
            AppDbContext db,
            IValidator<RsvpRequest> validator) =>
        {
            // Validação do payload (formato, limites)
            var validation = await validator.ValidateAsync(request);
            if (!validation.IsValid)
            {
                return Results.BadRequest(new
                {
                    errors = validation.Errors.Select(e => new { e.PropertyName, e.ErrorMessage })
                });
            }

            var normalizada = AdminInvitationLineEndpoints.Normalize(request.IdentificacaoNoConvite);

            // Busca linha cadastrada pelo Admin — sem expor lista (consulta por identificação exata)
            var line = await db.InvitationLines
                .Include(l => l.Rsvp)
                .FirstOrDefaultAsync(l => l.IdentificacaoNormalizada == normalizada);

            // Identificação inexistente ou inativa
            if (line == null || !line.Ativo)
            {
                return Results.UnprocessableEntity(new
                {
                    code = "INVITATION_NOT_FOUND",
                    message = $"A identificação '{request.IdentificacaoNoConvite}' não foi encontrada na lista de convidados."
                });
            }

            // Linha já respondida — chave de unicidade é a linha, não o e-mail
            if (line.Rsvp != null)
            {
                return Results.UnprocessableEntity(new
                {
                    code = "INVITATION_ALREADY_RESPONDED",
                    message = "Esta linha de convite já possui uma resposta registrada."
                });
            }

            // Adultos derivados do Admin; crianças do formulário
            var qtdAdultos = request.VaiComparecer ? line.QuantidadeAdultos : 0;
            var qtdCriancas = request.VaiComparecer ? request.QtdCriancas : 0;

            var rsvp = new Rsvp
            {
                Id = Guid.NewGuid(),
                IdentificacaoNoConvite = line.IdentificacaoNoConvite,
                InvitationLineId = line.Id,
                Email = request.Email.Trim().ToLowerInvariant(),
                Telefone = request.Telefone.Trim(),
                VaiComparecer = request.VaiComparecer,
                QtdAdultos = qtdAdultos,
                QtdCriancas = qtdCriancas,
                AceitouTermos = request.AceitouTermos,
                CriadoEm = DateTimeOffset.UtcNow
            };

            db.Rsvps.Add(rsvp);

            try
            {
                await db.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // Concorrência: outra requisição salvou antes (índice único em InvitationLineId)
                return Results.UnprocessableEntity(new
                {
                    code = "INVITATION_ALREADY_RESPONDED",
                    message = "Esta linha de convite já possui uma resposta registrada."
                });
            }

            return Results.Created($"/api/rsvp/{rsvp.Id}", new { id = rsvp.Id });
        })
        .RequireRateLimiting(rateLimitPolicy)
        .WithName("CreateRsvp")
        .WithSummary("Submete confirmação de presença por QR code genérico")
        .Produces<object>(StatusCodes.Status201Created)
        .Produces<object>(StatusCodes.Status400BadRequest)
        .Produces<object>(StatusCodes.Status422UnprocessableEntity)
        .Produces(StatusCodes.Status429TooManyRequests);

        return app;
    }
}
