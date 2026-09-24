using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace WeddingRsvp.Api.Models;

public record GiftOrderRequest(
    [Required, MaxLength(100)] string SenderName,
    [MaxLength(500)] string? Message,
    [Required, MinLength(1)] List<GiftOrderItemRequest> Items,
    string IdempotencyKey
);

public record GiftOrderItemRequest(
    [Required] Guid GiftId,
    [Required, Range(1, 100)] int Quantity
);

public record GiftOrderResponse(
    Guid Id,
    string CheckoutUrl,
    string AccessToken
);
