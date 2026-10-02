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
            var rsvps = await db.Rsvps.AsNoTracking().ToListAsync();
            var confirmados = rsvps.Where(r => r.VaiComparecer).ToList();
            var recusados = rsvps.Where(r => !r.VaiComparecer).ToList();
            var totalPessoas = confirmados.Sum(r => r.QtdAdultos + r.QtdCriancas);

            var linhasAtivas = await db.InvitationLines.AsNoTracking().Where(l => l.Ativo).CountAsync();
            var pessoasEsperadas = await db.InvitationLines.AsNoTracking().Where(l => l.Ativo).SumAsync(l => l.QuantidadeAdultos);
            var linhasRespondidas = rsvps.Select(r => r.InvitationLineId).Distinct().Count();
            var pendentes = linhasAtivas > linhasRespondidas ? linhasAtivas - linhasRespondidas : 0;

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
                    total = rsvps.Count,
                    confirmados = confirmados.Count,
                    recusados = recusados.Count,
                    totalPessoas,
                    linhasAtivas,
                    pendentes,
                    pessoasEsperadas
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
