using System;
using System.Collections.Generic;

namespace WeddingRsvp.Api.Models;

public record GiftOrderItemDetailsResponse(
    Guid GiftId,
    string Name,
    long UnitPriceCents,
    int Quantity
);

public record GiftOrderDetailsResponse(
    Guid Id,
    string Status,
    long TotalCents,
    string Currency,
    List<GiftOrderItemDetailsResponse> Items,
    string SenderName,
    string? Message,
    DateTimeOffset CreatedAtUtc,
    string? PaymentMethod,
    DateTimeOffset? ConfirmedAtUtc,
    DateTimeOffset? ReceivedAtUtc,
    string? CheckoutUrl
);
