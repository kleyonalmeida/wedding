using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using System.Linq;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Endpoints;

public static class PublicGiftEndpoints
{
    public static void MapPublicGiftEndpoints(this IEndpointRouteBuilder routes)
    {
        routes.MapGet("/api/images/{key}", async (string key, HttpContext context, GiftImageStore store, AppDbContext db) =>
        {
            var isThumb = key.StartsWith("thumb_", StringComparison.Ordinal);
            var actualKey = isThumb ? key[6..] : key;

            if (actualKey != Path.GetFileName(actualKey) || actualKey.Contains("..")) return Results.BadRequest();
            var image = await db.GiftImages.AsNoTracking().FirstOrDefaultAsync(i => i.StorageKey == actualKey && i.Gift != null && i.Gift.Active && i.Gift.DeletedAtUtc == null);
            if (image == null) return Results.NotFound();
            var path = isThumb ? store.PathForThumb(actualKey) : store.PathFor(actualKey);
            var fallbackToOriginal = isThumb && !File.Exists(path);
            if (fallbackToOriginal) path = store.PathFor(actualKey);

            if (!File.Exists(path)) return Results.NotFound();

            context.Response.OnStarting(() => {
                context.Response.Headers.CacheControl = fallbackToOriginal
                    ? "no-store"
                    : "public, max-age=604800, immutable";
                return Task.CompletedTask;
            });
            return Results.File(path, image.MimeType);
        });
        var group = routes.MapGroup("/api/gifts").WithTags("Public Gifts");

        group.MapGet("/", async (AppDbContext db) =>
        {
            var gifts = await db.Set<Gift>()
                .AsNoTracking()
                .Include(g => g.Images)
                .Where(g => g.Active && g.DeletedAtUtc == null)
                .OrderBy(g => g.DisplayOrder)
                .ToListAsync();
            var result = gifts
                .Select(g => new
                {
                    g.Id,
                    g.Name,
                    g.Slug,
                    g.ShortDescription,
                    g.Description,
                    g.PriceCents,
                    g.Category,
                    g.Featured,
                    SoldOut = g.StockRemaining == 0,
                    ImageUrl = g.Images.Where(img => img.IsPrimary)
                        .Select(img => $"/api/images/thumb_{img.StorageKey}").FirstOrDefault()
                })
                .ToList();

            return Results.Ok(result);
        });

        group.MapGet("/{slug}", async (AppDbContext db, string slug) =>
        {
            var gift = await db.Set<Gift>()
                .AsNoTracking()
                .Include(g => g.Images)
                .Where(g => g.Slug == slug && g.Active && g.DeletedAtUtc == null)
                .FirstOrDefaultAsync();
            if (gift == null) return Results.NotFound();
            return Results.Ok(new
            {
                gift.Id,
                gift.Name,
                gift.Slug,
                gift.ShortDescription,
                gift.Description,
                gift.PriceCents,
                gift.Category,
                gift.Featured,
                SoldOut = gift.StockRemaining == 0,
                ImageUrl = gift.Images.Where(img => img.IsPrimary)
                    .Select(img => $"/api/images/{img.StorageKey}").FirstOrDefault()
            });
        });
    }
}
