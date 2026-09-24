namespace WeddingRsvp.Api.Payments;

public static class PaymentStatusMapper
{
    public static bool ShouldApplyWebhookStatus(string current, string incoming)
    {
        if (current == incoming) return true;
        return current switch
        {
            "Received" => incoming is "Refunded" or "Disputed",
            "Confirmed" => incoming is "Received" or "Refunded" or "Disputed",
            "Refunded" or "Disputed" => false,
            "Cancelled" or "Overdue" => incoming is "Confirmed" or "Received" or "Refunded" or "Disputed",
            _ => true
        };
    }

    public static string MapAsaasStatus(string asaasStatus)
    {
        return asaasStatus switch
        {
            "PENDING" => "Pending",
            "CONFIRMED" => "Confirmed",
            "RECEIVED" => "Received",
            "OVERDUE" => "Overdue",
            "CANCELLED" => "Cancelled",
            "REFUNDED" => "Refunded",
            "REFUND_REQUESTED" => "Refunded",
            "CHARGEBACK_REQUESTED" => "Disputed",
            "CHARGEBACK_DISPUTE" => "Disputed",
            "AWAITING_CHARGEBACK_REVERSAL" => "Disputed",
            _ => "UnknownNeedsReview"
        };
    }
}
