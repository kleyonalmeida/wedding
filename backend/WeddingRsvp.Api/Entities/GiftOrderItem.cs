using System;

namespace WeddingRsvp.Api.Entities;

public class GiftOrderItem
{
    public Guid Id { get; set; }
    
    public Guid OrderId { get; set; }
    public GiftOrder? Order { get; set; }
    
    public Guid GiftId { get; set; }
    public Gift? Gift { get; set; }
    
    public string GiftNameSnapshot { get; set; } = string.Empty;
    public long PriceCentsSnapshot { get; set; }
    public int Quantity { get; set; }
}
