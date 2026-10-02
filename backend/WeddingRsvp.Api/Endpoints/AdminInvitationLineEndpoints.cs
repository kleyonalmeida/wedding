using FluentValidation;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Models;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Endpoints;

/// <summary>
/// Endpoints autenticados para o Admin gerenciar linhas de convite.
/// POST   /api/admin/invitation-lines      — Cadastrar
/// GET    /api/admin/invitation-lines      — Listar (paginado)
/// GET    /api/admin/invitation-lines/{id} — Detalhe
/// PUT    /api/admin/invitation-lines/{id} — Editar
/// DELETE /api/admin/invitation-lines/{id} — Desativar
/// </summary>
public static class AdminInvitationLineEndpoints
{
    public static void MapAdminInvitationLineEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/invitation-lines")
            .RequireAuthorization("SuperAdmin")
            .RequireRateLimiting("AdminPolicy")
            .WithTags("Admin - Linhas de Convite");

        // ── POST — Cadastrar linha ────────────────────────────────────────────
        group.MapPost("/", async (
            CreateInvitationLineRequest request,
            AppDbContext db,
            IValidator<CreateInvitationLineRequest> validator) =>
        {
            var validation = await validator.ValidateAsync(request);
            if (!validation.IsValid)
            {
                return Results.BadRequest(validation.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
            }

            var normalizada = Normalize(request.IdentificacaoNoConvite);

            // Impede duplicata de identificação normalizada
            var existe = await db.InvitationLines
                .AnyAsync(l => l.IdentificacaoNormalizada == normalizada);

            if (existe)
            {
                return Results.Conflict(new
                {
                    message = "Já existe uma linha de convite com esta identificação.",
                    identificacao = request.IdentificacaoNoConvite
                });
            }

            var line = new InvitationLine
            {
                Id = Guid.NewGuid(),
                IdentificacaoNoConvite = request.IdentificacaoNoConvite.Trim(),
                IdentificacaoNormalizada = normalizada,
                QuantidadeAdultos = request.QuantidadeAdultos,
                Ativo = true,
                CriadoEm = DateTimeOffset.UtcNow
            };

            db.InvitationLines.Add(line);
            await db.SaveChangesAsync();

            return Results.Created($"/api/admin/invitation-lines/{line.Id}", MapToResponse(line));
        })
        .WithName("CreateInvitationLine")
        .WithSummary("Cadastra uma linha de convite")
        .Produces<object>(StatusCodes.Status201Created)
        .Produces<object>(StatusCodes.Status400BadRequest)
        .Produces<object>(StatusCodes.Status409Conflict);

        // ── GET — Listar ─────────────────────────────────────────────────────
        group.MapGet("/", async (
            AppDbContext db,
            string? search = null,
            bool? ativo = null,
            bool? respondida = null,
            bool? pendente = null,
            int page = 1,
            int pageSize = 15) =>
        {
            var query = db.InvitationLines.AsNoTracking().AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = Normalize(search);
                query = query.Where(l => l.IdentificacaoNormalizada.Contains(s));
            }

            if (ativo.HasValue)
                query = query.Where(l => l.Ativo == ativo.Value);

            if (respondida.HasValue)
                query = query.Where(l => respondida.Value ? l.Rsvp != null : l.Rsvp == null);

            if (pendente.HasValue)
            {
                if (pendente.Value) query = query.Where(l => l.Rsvp == null);
                else query = query.Where(l => l.Rsvp != null);
            }

            query = query.OrderBy(l => l.IdentificacaoNormalizada);

            var total = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
                .Select(l => new 
                {
                    l.Id,
                    l.IdentificacaoNoConvite,
                    l.IdentificacaoNormalizada,
                    l.QuantidadeAdultos,
                    l.Ativo,
                    l.CriadoEm,
                    RsvpId = l.Rsvp != null ? (Guid?)l.Rsvp.Id : null,
                    VaiComparecer = l.Rsvp != null ? (bool?)l.Rsvp.VaiComparecer : null,
                    QtdAdultosConfirmados = l.Rsvp != null ? (int?)l.Rsvp.QtdAdultos : null,
                    QtdCriancasConfirmadas = l.Rsvp != null ? (int?)l.Rsvp.QtdCriancas : null,
                    DataResposta = l.Rsvp != null ? (DateTimeOffset?)l.Rsvp.CriadoEm : null
                })
                .ToListAsync();

            return Results.Ok(new
            {
                data = items,
                total,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(total / (double)pageSize)
            });
        })
        .WithName("ListInvitationLines")
        .WithSummary("Lista linhas de convite paginadas");

        // ── GET — Detalhe ─────────────────────────────────────────────────────
        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var line = await db.InvitationLines
                .AsNoTracking()
                .Include(l => l.Rsvp)
                .FirstOrDefaultAsync(l => l.Id == id);

            return line != null ? Results.Ok(MapToResponse(line)) : Results.NotFound();
        })
        .WithName("GetInvitationLine")
        .WithSummary("Retorna uma linha de convite pelo Id");

        // ── PUT — Editar ──────────────────────────────────────────────────────
        group.MapPut("/{id:guid}", async (
            Guid id,
            UpdateInvitationLineRequest request,
            AppDbContext db,
            IValidator<UpdateInvitationLineRequest> validator,
            IAuditService auditService) =>
        {
            var validation = await validator.ValidateAsync(request);
            if (!validation.IsValid)
            {
                return Results.BadRequest(validation.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
            }

            var line = await db.InvitationLines
                .Include(l => l.Rsvp)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (line == null) return Results.NotFound();

            var oldValues = new { line.QuantidadeAdultos, line.Ativo };

            if (request.QuantidadeAdultos.HasValue)
            {
                line.QuantidadeAdultos = request.QuantidadeAdultos.Value;
                if (line.Rsvp?.VaiComparecer == true)
                    line.Rsvp.QtdAdultos = request.QuantidadeAdultos.Value;
            }

            if (request.Ativo.HasValue)
                line.Ativo = request.Ativo.Value;

            line.AtualizadoEm = DateTimeOffset.UtcNow;

            var newValues = new { line.QuantidadeAdultos, line.Ativo };

            await auditService.LogAsync(
                action: "Update",
                entityType: "InvitationLine",
                entityId: id.ToString(),
                description: $"Linha de convite editada: {request.Motivo}",
                oldValues: oldValues,
                newValues: newValues);

            await db.SaveChangesAsync();
            return Results.Ok(MapToResponse(line));
        })
        .WithName("UpdateInvitationLine")
        .WithSummary("Edita quantidade de adultos ou estado ativo de uma linha");

        // ── DELETE — Desativar (soft delete) ──────────────────────────────────
        group.MapDelete("/{id:guid}", async (
            Guid id,
            AppDbContext db,
            IAuditService auditService) =>
        {
            var line = await db.InvitationLines.FindAsync(id);
            if (line == null) return Results.NotFound();

            line.Ativo = false;
            line.AtualizadoEm = DateTimeOffset.UtcNow;

            await auditService.LogAsync(
                action: "Deactivate",
                entityType: "InvitationLine",
                entityId: id.ToString(),
                description: "Linha de convite desativada pelo Admin.",
                oldValues: new { Ativo = true },
                newValues: new { Ativo = false });

            await db.SaveChangesAsync();
            return Results.Ok(MapToResponse(line));
        })
        .WithName("DeactivateInvitationLine")
        .WithSummary("Desativa uma linha de convite (soft delete)");
    }

    /// <summary>
    /// Normaliza a identificação para comparação: NFC + trim + caixa invariável.
    /// Mantém acentos e espaços internos: "Jorge" ≠ "Jorje".
    /// </summary>
    public static string Normalize(string input) =>
        input.Trim().Normalize(System.Text.NormalizationForm.FormC).ToUpperInvariant();

    private static object MapToResponse(InvitationLine line) => new
    {
        line.Id,
        line.IdentificacaoNoConvite,
        line.QuantidadeAdultos,
        line.Ativo,
        line.CriadoEm,
        line.AtualizadoEm,
        Respondida = line.Rsvp != null,
        Rsvp = line.Rsvp == null ? null : new
        {
            line.Rsvp.Id,
            line.Rsvp.VaiComparecer,
            line.Rsvp.QtdAdultos,
            line.Rsvp.QtdCriancas,
            line.Rsvp.CriadoEm
        }
    };
}
