using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminAttendanceEndpoints
{
    public static void MapAdminAttendanceEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/attendance")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        // Listar RSVPs paginado — incluindo identificação da linha
        group.MapGet("/", async (
            AppDbContext db,
            string? search = null,
            bool? vaiComparecer = null,
            int page = 1,
            int pageSize = 20) =>
        {
            var query = db.Rsvps
                .AsNoTracking()
                .Include(r => r.InvitationLine)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                var s = search.ToLower();
                query = query.Where(r =>
                    r.IdentificacaoNoConvite.ToLower().Contains(s) ||
                    r.Email.ToLower().Contains(s));
            }

            if (vaiComparecer.HasValue)
                query = query.Where(r => r.VaiComparecer == vaiComparecer.Value);

            query = query.OrderByDescending(r => r.CriadoEm);

            var total = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            return Results.Ok(new
            {
                data = items.Select(r => new
                {
                    r.Id,
                    r.IdentificacaoNoConvite,
                    r.Email,
                    r.Telefone,
                    r.VaiComparecer,
                    r.QtdAdultos,
                    r.QtdCriancas,
                    r.CriadoEm,
                    InvitationLineId = r.InvitationLineId
                }),
                total,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(total / (double)pageSize)
            });
        });

        // Resumo estatístico — por linhas de convite
        group.MapGet("/summary", async (AppDbContext db) =>
        {
            var totalLinhas = await db.InvitationLines.CountAsync(l => l.Ativo);
            var linhasComResposta = await db.InvitationLines
                .AsNoTracking()
                .Include(l => l.Rsvp)
                .Where(l => l.Ativo && l.Rsvp != null)
                .ToListAsync();

            var linhasConfirmadas = linhasComResposta.Where(l => l.Rsvp!.VaiComparecer).ToList();
            var linhasRecusadas = linhasComResposta.Where(l => !l.Rsvp!.VaiComparecer).ToList();
            var linhasPendentes = totalLinhas - linhasComResposta.Count;

            var totalAdultos = linhasConfirmadas.Sum(l => l.Rsvp!.QtdAdultos);
            var totalCriancas = linhasConfirmadas.Sum(l => l.Rsvp!.QtdCriancas);

            return Results.Ok(new
            {
                totalLinhas,
                linhasPendentes,
                linhasConfirmadas = linhasConfirmadas.Count,
                linhasRecusadas = linhasRecusadas.Count,
                totalAdultos,
                totalCriancas,
                totalPessoas = totalAdultos + totalCriancas
            });
        });

        // Detalhe de um RSVP
        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var rsvp = await db.Rsvps
                .AsNoTracking()
                .Include(r => r.InvitationLine)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (rsvp == null) return Results.NotFound();

            return Results.Ok(new
            {
                rsvp.Id,
                rsvp.IdentificacaoNoConvite,
                rsvp.Email,
                rsvp.Telefone,
                rsvp.VaiComparecer,
                rsvp.QtdAdultos,
                rsvp.QtdCriancas,
                rsvp.CriadoEm,
                rsvp.InvitationLineId
            });
        });

        // Edição manual pelo Admin (com auditoria e motivo obrigatório)
        group.MapPatch("/{id:guid}", async (
            Guid id,
            RsvpPatchRequest request,
            AppDbContext db,
            IAuditService auditService) =>
        {
            var rsvp = await db.Rsvps.Include(r => r.InvitationLine)
                .FirstOrDefaultAsync(r => r.Id == id);
            if (rsvp == null) return Results.NotFound();

            if (string.IsNullOrWhiteSpace(request.Motivo))
            {
                return Results.BadRequest(new { message = "Um motivo para a edição manual é obrigatório para fins de auditoria." });
            }

            var oldValues = new
            {
                rsvp.VaiComparecer,
                rsvp.QtdAdultos,
                rsvp.QtdCriancas
            };

            if (request.QtdCriancas is < 0 or > 10)
                return Results.BadRequest(new { message = "Quantidade de crianças deve ser entre 0 e 10." });

            if (request.VaiComparecer.HasValue) rsvp.VaiComparecer = request.VaiComparecer.Value;
            rsvp.QtdAdultos = rsvp.VaiComparecer
                ? rsvp.InvitationLine!.QuantidadeAdultos : 0;
            rsvp.QtdCriancas = rsvp.VaiComparecer
                ? request.QtdCriancas ?? rsvp.QtdCriancas : 0;

            var newValues = new
            {
                rsvp.VaiComparecer,
                rsvp.QtdAdultos,
                rsvp.QtdCriancas
            };

            await auditService.LogAsync(
                action: "Update",
                entityType: "Rsvp",
                entityId: id.ToString(),
                description: $"RSVP editado manualmente: {request.Motivo}",
                oldValues: oldValues,
                newValues: newValues);

            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                rsvp.Id,
                rsvp.IdentificacaoNoConvite,
                rsvp.VaiComparecer,
                rsvp.QtdAdultos,
                rsvp.QtdCriancas
            });
        });
    }
}

public record RsvpPatchRequest(
    bool? VaiComparecer,
    int? QtdCriancas,
    string? Motivo
);
