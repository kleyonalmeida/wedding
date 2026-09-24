using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminAttendanceEndpoints
{
    public static void MapAdminAttendanceEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/attendance")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        // Listar RSVPs paginado
        group.MapGet("/", async (
            AppDbContext db,
            string? search = null,
            bool? vaiComparecer = null,
            int page = 1,
            int pageSize = 20) =>
        {
            var query = db.Rsvps.AsNoTracking().AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                var s = search.ToLower();
                query = query.Where(r => r.Nome.ToLower().Contains(s) || r.Email.ToLower().Contains(s));
            }

            if (vaiComparecer.HasValue)
            {
                query = query.Where(r => r.VaiComparecer == vaiComparecer.Value);
            }

            query = query.OrderByDescending(r => r.CriadoEm);

            var total = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            return Results.Ok(new
            {
                data = items,
                total,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(total / (double)pageSize)
            });
        });

        // Resumo estatístico
        group.MapGet("/summary", async (AppDbContext db) =>
        {
            var rsvps = await db.Rsvps.AsNoTracking().ToListAsync();
            
            var confirmados = rsvps.Where(r => r.VaiComparecer).ToList();
            var naoVao = rsvps.Where(r => !r.VaiComparecer).ToList();
            
            var totalAdultos = confirmados.Sum(r => r.QtdAdultos);
            var totalCriancas = confirmados.Sum(r => r.QtdCriancas);

            return Results.Ok(new
            {
                totalRespostas = rsvps.Count,
                confirmados = confirmados.Count,
                naoVao = naoVao.Count,
                totalAdultos,
                totalCriancas,
                totalPessoas = totalAdultos + totalCriancas
            });
        });

        // Detalhe
        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var rsvp = await db.Rsvps.FindAsync(id);
            return rsvp != null ? Results.Ok(rsvp) : Results.NotFound();
        });

        // Edição manual
        group.MapPatch("/{id:guid}", async (
            Guid id,
            RsvpPatchRequest request,
            AppDbContext db,
            IAuditService auditService) =>
        {
            var rsvp = await db.Rsvps.FindAsync(id);
            if (rsvp == null) return Results.NotFound();

            if (string.IsNullOrWhiteSpace(request.Motivo))
            {
                return Results.BadRequest(new { message = "Um motivo para a edição manual é obrigatório para fins de auditoria." });
            }

            var oldValues = new
            {
                rsvp.VaiComparecer,
                rsvp.QtdAdultos,
                rsvp.QtdCriancas,
                rsvp.Observacoes
            };

            if (request.VaiComparecer.HasValue) rsvp.VaiComparecer = request.VaiComparecer.Value;
            if (request.QtdAdultos.HasValue) rsvp.QtdAdultos = request.QtdAdultos.Value;
            if (request.QtdCriancas.HasValue) rsvp.QtdCriancas = request.QtdCriancas.Value;
            if (request.Observacoes != null) rsvp.Observacoes = request.Observacoes;

            var newValues = new
            {
                rsvp.VaiComparecer,
                rsvp.QtdAdultos,
                rsvp.QtdCriancas,
                rsvp.Observacoes
            };

            await auditService.LogAsync(
                action: "Update",
                entityType: "Rsvp",
                entityId: id.ToString(),
                description: $"RSVP editado manualmente: {request.Motivo}",
                oldValues: oldValues,
                newValues: newValues);

            await db.SaveChangesAsync();

            return Results.Ok(rsvp);
        });
    }
}

public record RsvpPatchRequest(
    bool? VaiComparecer,
    int? QtdAdultos,
    int? QtdCriancas,
    string? Observacoes,
    string? Motivo
);
