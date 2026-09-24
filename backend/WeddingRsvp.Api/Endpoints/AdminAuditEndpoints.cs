using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminAuditEndpoints
{
    public static void MapAdminAuditEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/audit-logs")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        group.MapGet("/", async (
            AppDbContext db,
            int page = 1,
            int pageSize = 20) =>
        {
            var query = db.AuditLogs.AsNoTracking().OrderByDescending(x => x.TimestampUtc);

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

        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var log = await db.AuditLogs.FindAsync(id);
            return log != null ? Results.Ok(log) : Results.NotFound();
        });
    }
}
