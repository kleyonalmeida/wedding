using System;

namespace WeddingRsvp.Api.Entities;

public class PaymentAttempt
{
    public Guid Id { get; set; }
    
    public Guid OrderId { get; set; }
    public GiftOrder? Order { get; set; }
    
    public string Gateway { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public string IdempotencyKey { get; set; } = string.Empty;
    public string RequestHash { get; set; } = string.Empty;
    public string? GatewayCheckoutId { get; set; }
    public string? CheckoutUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    
    public DateTimeOffset? ExpiresAtUtc { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset? UpdatedAtUtc { get; set; }
    
    public Guid Version { get; set; }
}
