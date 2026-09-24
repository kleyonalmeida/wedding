using System;

namespace WeddingRsvp.Api.Entities;

public class AppSetting
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    
    public int Revision { get; set; }
    public Guid? AuthorUserId { get; set; }
    public DateTimeOffset UpdatedAtUtc { get; set; }
}
