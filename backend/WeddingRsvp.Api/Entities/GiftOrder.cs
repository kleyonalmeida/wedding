using System;
using System.Collections.Generic;

namespace WeddingRsvp.Api.Entities;

public class GiftOrder
{
    public Guid Id { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string? Message { get; set; }
    public string Currency { get; set; } = "BRL";
    public long TotalCents { get; set; }
    public string Status { get; set; } = "Pending";
    public string? PublicTokenHash { get; set; }
    
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset? UpdatedAtUtc { get; set; }
    
    public Guid Version { get; set; }

    public ICollection<GiftOrderItem> Items { get; set; } = new List<GiftOrderItem>();
}
