using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminDashboardEndpoints
{
    public static void MapAdminDashboardEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/dashboard")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        group.MapGet("/summary", async (AppDbContext db) =>
        {
            // RSVPs
            var linhasAtivasList = await db.InvitationLines
                .AsNoTracking()
                .Include(l => l.Rsvp)
                .Where(l => l.Ativo)
                .ToListAsync();

            var confirmadas = linhasAtivasList.Where(l => l.Rsvp != null && l.Rsvp.VaiComparecer).ToList();
            var recusadas = linhasAtivasList.Where(l => l.Rsvp != null && !l.Rsvp.VaiComparecer).ToList();
            var pendentesList = linhasAtivasList.Where(l => l.Rsvp == null).ToList();

            var totalPessoas = confirmadas.Sum(l => l.Rsvp!.QtdAdultos + l.Rsvp!.QtdCriancas);
            var linhasAtivas = linhasAtivasList.Count;
            var pessoasEsperadas = linhasAtivasList.Sum(l => l.QuantidadeAdultos + l.QuantidadeCriancas);
            var pendentes = pendentesList.Count;
            var pessoasPendentes = pendentesList.Sum(l => l.QuantidadeAdultos + l.QuantidadeCriancas);
            var rsvpsTotal = confirmadas.Count + recusadas.Count;

            // Produtos
            var gifts = await db.Gifts.AsNoTracking().ToListAsync();
            var totalGifts = gifts.Count;
            var activeGifts = gifts.Count(g => g.Active && g.DeletedAtUtc == null);
            var inactiveGifts = totalGifts - activeGifts;

            // Pedidos confirmados por webhook de checkout ou cobrança.
            var paidOrders = await db.GiftOrders.AsNoTracking().CountAsync(o => o.Status == "Confirmed" || o.Status == "Received");
            
            var records = AdminFinancialRecords.Query(db);
            var pendingPayments = await records.CountAsync(p => p.Status == "Pending");
            var confirmedPayments = await records.CountAsync(p => p.Status == "Confirmed");
            var cancelledPayments = await records.CountAsync(p => p.Status == "Cancelled" || p.Status == "Overdue");
            var totalConfirmedCents = await records.Where(p => p.Status == "Confirmed")
                .SumAsync(p => (long?)(p.AmountCents - p.RefundedCents)) ?? 0;
            var totalReceivedCents = await records.Where(p => p.Status == "Received")
                .SumAsync(p => (long?)(p.AmountCents - p.RefundedCents)) ?? 0;
            var totalRaisedCents = totalConfirmedCents + totalReceivedCents;

            return Results.Ok(new
            {
                rsvps = new
                {
                    total = rsvpsTotal,
                    confirmados = confirmadas.Count,
                    recusados = recusadas.Count,
                    totalPessoas,
                    linhasAtivas,
                    pendentes,
                    pessoasEsperadas,
                    pessoasPendentes
                },
                products = new
                {
                    total = totalGifts,
                    ativos = activeGifts,
                    inativos = inactiveGifts
                },
                orders = new
                {
                    paidOrders
                },
                payments = new
                {
                    pending = pendingPayments,
                    confirmed = confirmedPayments,
                    cancelled = cancelledPayments,
                    totalConfirmedCents,
                    totalRaisedCents,
                    totalReceivedCents
                }
            });
        });

        group.MapGet("/activity", async (AppDbContext db, int limit = 10) =>
        {
            var activities = await db.AuditLogs
                .AsNoTracking()
                .OrderByDescending(a => a.TimestampUtc)
                .Take(limit)
                .Select(a => new
                {
                    a.Id,
                    a.TimestampUtc,
                    a.Action,
                    a.EntityType,
                    a.Description
                })
                .ToListAsync();

            return Results.Ok(activities);
        });
    }
}
