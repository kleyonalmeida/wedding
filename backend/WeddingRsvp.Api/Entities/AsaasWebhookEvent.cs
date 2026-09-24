using System;

namespace WeddingRsvp.Api.Entities;

public class AsaasWebhookEvent
{
    public Guid Id { get; set; }
    
    // Escopado por ambiente (se usar uma base para ambos) -> vamos assumir que tem environment aqui ou no AsaasEventId
    public string AsaasEventId { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    
    public string? GatewayPaymentId { get; set; }
    public string? GatewayCheckoutId { get; set; }
    
    public string Payload { get; set; } = string.Empty; // Mínimo necessário ou cifrado
    
    public DateTimeOffset ReceivedAtUtc { get; set; }
    public DateTimeOffset? ProcessedAtUtc { get; set; }
    
    public string Status { get; set; } = "Pending";
    public int Attempts { get; set; }
    public DateTimeOffset? NextAttemptAtUtc { get; set; }
    
    public string? ErrorCode { get; set; }
}
