using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Payments;

public static class GiftInventory
{
    public static async Task<bool> ReserveAsync(AppDbContext db, Gift gift, int quantity, CancellationToken cancellationToken = default)
    {
        if (gift.StockRemaining == null) return true;
        if (gift.StockRemaining < quantity) return false;

        if (db.Database.IsRelational())
        {
            var updated = await db.Gifts.Where(g => g.Id == gift.Id && g.StockRemaining >= quantity)
                .ExecuteUpdateAsync(setters => setters.SetProperty(g => g.StockRemaining, g => g.StockRemaining - quantity), cancellationToken);
            return updated == 1;
        }

        gift.StockRemaining -= quantity;
        return true;
    }

    public static async Task ReleaseAsync(AppDbContext db, GiftOrder order, CancellationToken cancellationToken = default)
    {
        if (order.StockReleased) return;
        if (db.Database.IsRelational())
        {
            var claimed = await db.GiftOrders.Where(o => o.Id == order.Id && !o.StockReleased)
                .ExecuteUpdateAsync(setters => setters.SetProperty(o => o.StockReleased, true), cancellationToken);
            if (claimed == 0) return;
        }
        if (!db.Entry(order).Collection(o => o.Items).IsLoaded)
            await db.Entry(order).Collection(o => o.Items).LoadAsync(cancellationToken);

        foreach (var item in order.Items.Where(i => i.ReservedQuantity > 0))
        {
            if (db.Database.IsRelational())
            {
                await db.Gifts.Where(g => g.Id == item.GiftId && g.StockRemaining != null)
                    .ExecuteUpdateAsync(setters => setters.SetProperty(g => g.StockRemaining, g => g.StockRemaining + item.ReservedQuantity), cancellationToken);
            }
            else
            {
                var gift = await db.Gifts.FindAsync(new object[] { item.GiftId }, cancellationToken);
                if (gift?.StockRemaining != null) gift.StockRemaining += item.ReservedQuantity;
            }
        }
        order.StockReleased = true;
    }
}
