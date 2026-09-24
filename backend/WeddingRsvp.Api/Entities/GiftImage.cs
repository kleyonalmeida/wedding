using System;

namespace WeddingRsvp.Api.Entities;

public class GiftImage
{
    public Guid Id { get; set; }
    public Guid GiftId { get; set; }
    public Gift? Gift { get; set; }
    public string StorageKey { get; set; } = string.Empty;
    public string MimeType { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public long ByteLength { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsPrimary { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset? UpdatedAtUtc { get; set; }
}
