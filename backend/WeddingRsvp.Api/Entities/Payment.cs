using System;

namespace WeddingRsvp.Api.Entities;

public class Payment
{
    public Guid Id { get; set; }
    
    public Guid OrderId { get; set; }
    public GiftOrder? Order { get; set; }
    
    public Guid AttemptId { get; set; }
    public PaymentAttempt? Attempt { get; set; }
    
    public string Gateway { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public string GatewayPaymentId { get; set; } = string.Empty;
    public string? GatewayCustomerId { get; set; }
    
    public long AmountCents { get; set; }
    public long? NetCents { get; set; }
    public long RefundedCents { get; set; }
    
    public string Status { get; set; } = string.Empty;
    public string BillingType { get; set; } = string.Empty;
    public string? ExternalReference { get; set; }
    
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset? UpdatedAtUtc { get; set; }
    public DateTimeOffset? ConfirmedAtUtc { get; set; }
    public DateTimeOffset? ReceivedAtUtc { get; set; }
    public DateTimeOffset? CancelledAtUtc { get; set; }
}
