using System;

namespace WeddingRsvp.Api.Entities;

public class Gift
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ShortDescription { get; set; }
    public string? Description { get; set; }
    public long PriceCents { get; set; }
    public int? StockRemaining { get; set; }
    public string? ExternalUrl { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
    public bool Active { get; set; }
    public bool Featured { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset? UpdatedAtUtc { get; set; }
    public DateTimeOffset? DeletedAtUtc { get; set; }
    
    // Concurrency token
    public Guid Version { get; set; }

    public ICollection<GiftImage> Images { get; set; } = new List<GiftImage>();
}
