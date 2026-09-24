using System;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Payments;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Payments;

public class WebhookProcessor : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<WebhookProcessor> _logger;

    public WebhookProcessor(IServiceProvider serviceProvider, ILogger<WebhookProcessor> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessPendingWebhooksAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing webhooks in background service.");
            }
            
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
        }
    }

    private async Task ProcessPendingWebhooksAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var auditService = scope.ServiceProvider.GetRequiredService<IAuditService>();

        var pendingEvents = await db.Set<AsaasWebhookEvent>()
            .Where(e => e.Status == "Pending" && (e.NextAttemptAtUtc == null || e.NextAttemptAtUtc <= DateTimeOffset.UtcNow))
            .OrderBy(e => e.ReceivedAtUtc)
            .Take(10)
            .ToListAsync(cancellationToken);

        foreach (var evt in pendingEvents)
        {
            await ProcessEventAsync(evt, db, auditService, cancellationToken);
        }
    }

    private async Task ProcessEventAsync(AsaasWebhookEvent evt, AppDbContext db, IAuditService audit, CancellationToken cancellationToken)
    {
        using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var document = JsonDocument.Parse(evt.Payload);
            if (evt.GatewayCheckoutId != null && evt.GatewayPaymentId == null)
            {
                var checkout = document.RootElement.GetProperty("checkout");
                var attempt = await db.PaymentAttempts.Include(a => a.Order)
                    .FirstOrDefaultAsync(a => a.GatewayCheckoutId == evt.GatewayCheckoutId, cancellationToken);
                if (attempt == null || attempt.Order == null) throw new InvalidOperationException("Checkout attempt not found.");
                if (checkout.TryGetProperty("externalReference", out var reference) &&
                    reference.ValueKind == JsonValueKind.String && reference.GetString() != attempt.Id.ToString())
                    throw new InvalidOperationException("Checkout reference mismatch.");
                var status = evt.EventType switch
                {
                    "CHECKOUT_PAID" => "Confirmed",
                    "CHECKOUT_CANCELED" => "Cancelled",
                    "CHECKOUT_EXPIRED" => "Overdue",
                    _ => null
                };
                if (status != null && PaymentStatusMapper.ShouldApplyWebhookStatus(attempt.Order.Status, status))
                {
                    attempt.Order.Status = status!;
                    attempt.Order.UpdatedAtUtc = DateTimeOffset.UtcNow;
                }
                evt.Status = "Processed";
                evt.ProcessedAtUtc = DateTimeOffset.UtcNow;
                await db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return;
            }
            var paymentNode = document.RootElement.GetProperty("payment");
            
            var gatewayPaymentId = paymentNode.GetProperty("id").GetString();
            var statusStr = paymentNode.GetProperty("status").GetString();
            var newStatus = PaymentStatusMapper.MapAsaasStatus(statusStr!);
            
            var extRefNode = paymentNode.GetProperty("externalReference");
            string? extRef = extRefNode.ValueKind == JsonValueKind.String ? extRefNode.GetString() : null;
            
            var netValue = paymentNode.GetProperty("netValue").GetDecimal();
            var netCents = (long)(netValue * 100);

            Payment? payment = await db.Set<Payment>().FirstOrDefaultAsync(p => p.GatewayPaymentId == gatewayPaymentId, cancellationToken);
            var gatewayValueCents = (long)decimal.Round(paymentNode.GetProperty("value").GetDecimal() * 100m, 0);
            if (payment != null && (payment.AmountCents != gatewayValueCents ||
                (extRef != null && extRef != payment.AttemptId.ToString())))
                throw new InvalidOperationException("Existing payment does not match order.");

            if (payment == null)
            {
                if (string.IsNullOrEmpty(extRef) || !Guid.TryParse(extRef, out var attemptId))
                {
                    throw new Exception("Payment not found and no valid external reference.");
                }

                var attempt = await db.Set<PaymentAttempt>().Include(a => a.Order).FirstOrDefaultAsync(a => a.Id == attemptId, cancellationToken);
                if (attempt == null || attempt.Order == null)
                {
                    throw new Exception("Attempt or Order not found.");
                }
                if (gatewayValueCents != attempt.Order.TotalCents)
                    throw new InvalidOperationException("Payment value does not match order.");

                payment = new Payment
                {
                    Id = Guid.NewGuid(),
                    OrderId = attempt.OrderId,
                    AttemptId = attempt.Id,
                    Gateway = "Asaas",
                    Environment = attempt.Environment,
                    GatewayPaymentId = gatewayPaymentId!,
                    ExternalReference = extRef,
                    AmountCents = attempt.Order.TotalCents,
                    CreatedAtUtc = DateTimeOffset.UtcNow,
                    BillingType = paymentNode.GetProperty("billingType").GetString()!
                };
                db.Add(payment);
            }

            if (newStatus == "UnknownNeedsReview") throw new InvalidOperationException("Unknown payment status.");
            if (!PaymentStatusMapper.ShouldApplyWebhookStatus(payment.Status, newStatus))
            {
                evt.Status = "Processed";
                evt.ProcessedAtUtc = DateTimeOffset.UtcNow;
                await db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return;
            }
            payment.Status = newStatus;
            payment.NetCents = netCents;
            payment.UpdatedAtUtc = DateTimeOffset.UtcNow;

            if (newStatus == "Confirmed" && payment.ConfirmedAtUtc == null)
            {
                payment.ConfirmedAtUtc = DateTimeOffset.UtcNow;
            }
            if (newStatus == "Received" && payment.ReceivedAtUtc == null)
            {
                payment.ReceivedAtUtc = DateTimeOffset.UtcNow;
            }

            var order = payment.Order ?? await db.Set<GiftOrder>().FindAsync(new object[] { payment.OrderId }, cancellationToken);
            if (order != null && PaymentStatusMapper.ShouldApplyWebhookStatus(order.Status, newStatus))
            {
                order.Status = newStatus;
                order.UpdatedAtUtc = DateTimeOffset.UtcNow;
            }

            evt.Status = "Processed";
            evt.ProcessedAtUtc = DateTimeOffset.UtcNow;
            
            await audit.LogAsync(
                action: "WebhookProcessed",
                entityType: "Payment",
                entityId: payment.Id.ToString(),
                description: $"Payment status updated to {newStatus} via webhook {evt.AsaasEventId}",
                oldValues: null,
                newValues: null
            );

            await db.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync(cancellationToken);
            db.ChangeTracker.Clear();
            var failedEvent = await db.AsaasWebhookEvents.FindAsync(new object[] { evt.Id }, cancellationToken);
            if (failedEvent == null) return;
            failedEvent.Attempts++;
            failedEvent.ErrorCode = ex.GetType().Name;
            failedEvent.NextAttemptAtUtc = DateTimeOffset.UtcNow.AddMinutes(Math.Pow(2, failedEvent.Attempts));
            if (failedEvent.Attempts > 10) failedEvent.Status = "Failed";
            await db.SaveChangesAsync(cancellationToken);
            _logger.LogError(ex, "Error processing event {EventId}", evt.Id);
        }
    }
}
