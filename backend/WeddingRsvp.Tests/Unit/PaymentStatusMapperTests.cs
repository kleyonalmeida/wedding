using WeddingRsvp.Api.Payments;
using Xunit;

namespace WeddingRsvp.Tests.Unit;

public class PaymentStatusMapperTests
{
    [Theory]
    [InlineData("Received", "Confirmed", false)]
    [InlineData("Confirmed", "Pending", false)]
    [InlineData("Refunded", "Confirmed", false)]
    [InlineData("Disputed", "Received", false)]
    [InlineData("Pending", "Confirmed", true)]
    [InlineData("Confirmed", "Received", true)]
    [InlineData("Received", "Refunded", true)]
    [InlineData("Overdue", "Received", true)]
    public void WebhookStatusDoesNotRegress(string current, string incoming, bool expected)
    {
        Assert.Equal(expected, PaymentStatusMapper.ShouldApplyWebhookStatus(current, incoming));
    }
}
