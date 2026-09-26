using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Services;
using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminProductEndpoints
{
    public static void MapAdminProductEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/products")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        group.MapGet("/", async (
            AppDbContext db,
            int page = 1,
            int pageSize = 20) =>
        {
            var query = db.Gifts.AsNoTracking().Where(g => g.DeletedAtUtc == null).OrderBy(g => g.DisplayOrder);
            
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
            var gift = await db.Gifts.Include(g => g.Images).FirstOrDefaultAsync(g => g.Id == id && g.DeletedAtUtc == null);
            if (gift == null) return Results.NotFound();
            return Results.Ok(new
            {
                gift.Id, gift.Name, gift.Slug, gift.PriceCents, gift.StockRemaining, gift.ExternalUrl, gift.Category,
                gift.ShortDescription, gift.Description, gift.DisplayOrder, gift.Active,
                gift.Featured, gift.Version,
                images = gift.Images.Select(i => new { i.Id, imageUrl = $"/api/images/{i.StorageKey}", i.Width, i.Height, i.IsPrimary })
            });
        });

        group.MapPost("/", async (
            ProductCreateRequest request,
            AppDbContext db,
            IAuditService auditService) =>
        {
            if (!ValidProduct(request.Name, request.Slug, request.Category, request.PriceCents, request.StockRemaining, request.ExternalUrl))
                return Results.BadRequest(new { message = "Dados do produto inválidos." });
            var id = Guid.NewGuid();
            var slug = string.IsNullOrWhiteSpace(request.Slug) ? GenerateSlug(request.Name, id) : request.Slug.Trim();
            if (await db.Gifts.AnyAsync(g => g.Slug == slug))
            {
                return Results.Conflict(new { message = "Slug already exists." });
            }

            var gift = new Gift
            {
                Id = id,
                Name = request.Name,
                Slug = slug,
                PriceCents = request.PriceCents,
                StockRemaining = request.StockRemaining,
                ExternalUrl = NormalizeUrl(request.ExternalUrl),
                Category = request.Category,
                ShortDescription = request.ShortDescription,
                Description = request.Description,
                Active = true,
                Featured = false,
                DisplayOrder = request.DisplayOrder,
                CreatedAtUtc = DateTimeOffset.UtcNow,
                Version = Guid.NewGuid()
            };

            db.Gifts.Add(gift);
            await auditService.LogAsync("Create", "Gift", gift.Id.ToString(), $"Created product {gift.Name}", newValues: gift);
            await db.SaveChangesAsync();

            return Results.Created($"/api/admin/products/{gift.Id}", gift);
        });

        group.MapPut("/{id:guid}", async (
            Guid id,
            ProductUpdateRequest request,
            AppDbContext db,
            IAuditService auditService) =>
        {
            if (!ValidProduct(request.Name, request.Slug, request.Category, request.PriceCents, request.StockRemaining, request.ExternalUrl))
                return Results.BadRequest(new { message = "Dados do produto inválidos." });
            var gift = await db.Gifts.FirstOrDefaultAsync(g => g.Id == id && g.DeletedAtUtc == null);
            if (gift == null) return Results.NotFound();
            var slug = string.IsNullOrWhiteSpace(request.Slug) ? gift.Slug : request.Slug.Trim();

            if (slug != gift.Slug && await db.Gifts.AnyAsync(g => g.Slug == slug && g.Id != id))
            {
                return Results.Conflict(new { message = "Slug already exists." });
            }

            var oldValues = new
            {
                gift.Name, gift.Slug, gift.PriceCents, gift.StockRemaining, gift.ExternalUrl, gift.Category, gift.ShortDescription, gift.Description, gift.DisplayOrder
            };

            gift.Name = request.Name;
            gift.Slug = slug;
            gift.PriceCents = request.PriceCents;
            gift.StockRemaining = request.StockRemaining;
            gift.ExternalUrl = NormalizeUrl(request.ExternalUrl);
            gift.Category = request.Category;
            gift.ShortDescription = request.ShortDescription;
            gift.Description = request.Description;
            gift.DisplayOrder = request.DisplayOrder;
            gift.UpdatedAtUtc = DateTimeOffset.UtcNow;
            gift.Version = Guid.NewGuid(); // Concurrency token

            await auditService.LogAsync("Update", "Gift", gift.Id.ToString(), $"Updated product {gift.Name}", oldValues, gift);
            await db.SaveChangesAsync();

            return Results.Ok(gift);
        });

        group.MapDelete("/{id:guid}", async (Guid id, AppDbContext db, IAuditService auditService) =>
        {
            var gift = await db.Gifts.FirstOrDefaultAsync(g => g.Id == id && g.DeletedAtUtc == null);
            if (gift == null) return Results.NotFound();

            gift.DeletedAtUtc = DateTimeOffset.UtcNow;
            gift.Active = false;
            gift.UpdatedAtUtc = DateTimeOffset.UtcNow;

            await auditService.LogAsync("Delete", "Gift", gift.Id.ToString(), $"Soft deleted product {gift.Name}", newValues: new { gift.Active, gift.DeletedAtUtc });
            await db.SaveChangesAsync();

            return Results.NoContent();
        });

        group.MapPatch("/{id:guid}/status", async (Guid id, ProductStatusRequest request, AppDbContext db, IAuditService audit) =>
        {
            var gift = await db.Gifts.FirstOrDefaultAsync(g => g.Id == id && g.DeletedAtUtc == null);
            if (gift == null) return Results.NotFound();
            gift.Active = request.Active;
            gift.Featured = request.Featured;
            gift.UpdatedAtUtc = DateTimeOffset.UtcNow;
            await audit.LogAsync("ProductStatus", "Gift", id.ToString(), newValues: new { gift.Active, gift.Featured });
            await db.SaveChangesAsync();
            return Results.Ok(gift);
        });

        group.MapPatch("/{id:guid}/order", async (Guid id, ProductOrderRequest request, AppDbContext db, IAuditService audit) =>
        {
            var gift = await db.Gifts.FirstOrDefaultAsync(g => g.Id == id && g.DeletedAtUtc == null);
            if (gift == null) return Results.NotFound();
            gift.DisplayOrder = request.DisplayOrder;
            gift.UpdatedAtUtc = DateTimeOffset.UtcNow;
            await audit.LogAsync("ProductOrder", "Gift", id.ToString(), newValues: new { gift.DisplayOrder });
            await db.SaveChangesAsync();
            return Results.Ok(gift);
        });

        group.MapPost("/{id:guid}/images", async (Guid id, IFormFile image, AppDbContext db,
            GiftImageStore store, IAuditService audit, CancellationToken cancellationToken) =>
        {
            var gift = await db.Gifts.FindAsync(new object[] { id }, cancellationToken);
            if (gift == null || gift.DeletedAtUtc != null) return Results.NotFound();
            (string Key, string MimeType, long Length, int Width, int Height) saved;
            try { saved = await store.SaveAsync(image, cancellationToken); }
            catch (ArgumentException ex) { return Results.BadRequest(new { message = ex.Message }); }
            try
            {
                await using var transaction = db.Database.IsRelational()
                    ? await db.Database.BeginTransactionAsync(cancellationToken) : null;
                var images = await db.GiftImages.Where(i => i.GiftId == id).ToListAsync(cancellationToken);
                db.GiftImages.RemoveRange(images);
                if (images.Count > 0) await db.SaveChangesAsync(cancellationToken);
                var item = new GiftImage
                {
                    Id = Guid.NewGuid(), GiftId = id, StorageKey = saved.Key,
                    MimeType = saved.MimeType, ByteLength = saved.Length, Width = saved.Width, Height = saved.Height,
                    IsPrimary = true, DisplayOrder = images.Count, CreatedAtUtc = DateTimeOffset.UtcNow
                };
                db.GiftImages.Add(item);
                await audit.LogAsync("UploadImage", "Gift", id.ToString());
                await db.SaveChangesAsync(cancellationToken);
                if (transaction != null) await transaction.CommitAsync(cancellationToken);
                foreach (var previous in images)
                {
                    try { File.Delete(store.PathFor(previous.StorageKey)); }
                    catch (IOException) { /* The database already points to the new image. */ }
                    catch (UnauthorizedAccessException) { /* Cleanup can be retried operationally. */ }
                }
                return Results.Created($"/api/images/{saved.Key}", new { imageUrl = $"/api/images/{saved.Key}" });
            }
            catch
            {
                File.Delete(store.PathFor(saved.Key));
                throw;
            }
        }).DisableAntiforgery().WithMetadata(new RequestSizeLimitAttribute(10 * 1024 * 1024));
        
    }

    private static bool ValidProduct(string name, string? slug, string category, long priceCents, int? stockRemaining, string? externalUrl) =>
        !string.IsNullOrWhiteSpace(name) && name.Length <= 150 &&
        (string.IsNullOrWhiteSpace(slug) || slug.Trim().Length <= 150) &&
        !string.IsNullOrWhiteSpace(category) && priceCents > 0 && priceCents <= 10_000_000 &&
        (stockRemaining == null || stockRemaining is >= 0 and <= 1_000_000) &&
        (string.IsNullOrWhiteSpace(externalUrl) ||
         (externalUrl.Length <= 2048 && Uri.TryCreate(externalUrl.Trim(), UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps));

    private static string? NormalizeUrl(string? url) => string.IsNullOrWhiteSpace(url) ? null : url.Trim();

    private static string GenerateSlug(string name, Guid id)
    {
        var normalized = name.Normalize(NormalizationForm.FormD);
        var ascii = new string(normalized.Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark).ToArray());
        var baseSlug = Regex.Replace(ascii.ToLowerInvariant(), "[^a-z0-9]+", "-").Trim('-');
        if (baseSlug.Length > 130) baseSlug = baseSlug[..130].TrimEnd('-');
        if (baseSlug.Length == 0) baseSlug = "presente";
        return $"{baseSlug}-{id.ToString("N")[..8]}";
    }
}

public record ProductCreateRequest(
    string Name,
    string? Slug,
    long PriceCents,
    string Category,
    string? ShortDescription,
    string? Description,
    int DisplayOrder = 0,
    int? StockRemaining = null,
    string? ExternalUrl = null
);

public record ProductUpdateRequest(
    string Name,
    string? Slug,
    long PriceCents,
    string Category,
    string? ShortDescription,
    string? Description,
    int DisplayOrder = 0,
    int? StockRemaining = null,
    string? ExternalUrl = null
);
public record ProductStatusRequest(bool Active, bool Featured);
public record ProductOrderRequest(int DisplayOrder);
