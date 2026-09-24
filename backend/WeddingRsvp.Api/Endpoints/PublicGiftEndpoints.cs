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
        routes.MapGet("/api/images/{key}", async (string key, GiftImageStore store, AppDbContext db) =>
        {
            if (key != Path.GetFileName(key) || key.Contains("..")) return Results.BadRequest();
            var image = await db.GiftImages.AsNoTracking().FirstOrDefaultAsync(i => i.StorageKey == key && i.Gift != null && i.Gift.Active && i.Gift.DeletedAtUtc == null);
            if (image == null) return Results.NotFound();
            var path = store.PathFor(key);
            return File.Exists(path) ? Results.File(path, image.MimeType) : Results.NotFound();
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
                    ImageUrl = g.Images.Where(img => img.IsPrimary)
                        .Select(img => $"/api/images/{img.StorageKey}").FirstOrDefault()
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
                ImageUrl = gift.Images.Where(img => img.IsPrimary)
                    .Select(img => $"/api/images/{img.StorageKey}").FirstOrDefault()
            });
        });
    }
}
