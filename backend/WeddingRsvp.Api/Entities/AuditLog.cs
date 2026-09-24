using System;

namespace WeddingRsvp.Api.Entities;

public class AuditLog
{
    public Guid Id { get; set; }
    public DateTimeOffset TimestampUtc { get; set; }
    
    public Guid? UserId { get; set; } // Opcional se for sistema/anônimo
    
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string? EntityId { get; set; }
    
    public string Description { get; set; } = string.Empty;
    
    public string? OldValues { get; set; } // Serializado JSON com campos permitidos
    public string? NewValues { get; set; }
    
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? CorrelationId { get; set; }
    
    public bool Success { get; set; }
}
