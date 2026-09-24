using System.Threading;
using System.Threading.Tasks;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Payments;

public interface IPaymentGateway
{
    Task<GatewayCheckoutResponse> CreateCheckoutAsync(PaymentAttempt attempt, GiftOrder order, string accessToken, CancellationToken cancellationToken = default);
    Task<GatewayPaymentResponse> GetPaymentStatusAsync(string gatewayPaymentId, CancellationToken cancellationToken = default);
}

public record GatewayCheckoutResponse(string CheckoutId, string CheckoutUrl);
public record GatewayPaymentResponse(string Status, long NetCents, string BillingType);
