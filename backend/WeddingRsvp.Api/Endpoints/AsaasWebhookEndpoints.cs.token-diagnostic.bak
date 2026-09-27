using System;
using System.Security.Cryptography;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using Npgsql;
using Microsoft.AspNetCore.Http.Features;

namespace WeddingRsvp.Api.Endpoints;

public static class AsaasWebhookEndpoints
{
    public static void MapAsaasWebhookEndpoints(this IEndpointRouteBuilder routes)
    {
        routes.MapPost("/api/webhooks/asaas", async (
            HttpRequest request,
            AppDbContext db,
            IConfiguration config,
            ILoggerFactory loggerFactory) =>
        {
            var logger = loggerFactory.CreateLogger("AsaasWebhookEndpoints");
            const long maxBodyBytes = 1024 * 1024;
            if (request.ContentLength > maxBodyBytes) return Results.StatusCode(StatusCodes.Status413PayloadTooLarge);
            var sizeFeature = request.HttpContext.Features.Get<IHttpMaxRequestBodySizeFeature>();
            if (sizeFeature is { IsReadOnly: false }) sizeFeature.MaxRequestBodySize = maxBodyBytes;
            
            var tokenHeader = request.Headers["asaas-access-token"].ToString();
            var configuredToken = config["Asaas:WebhookAuthToken"];
            
            if (string.IsNullOrEmpty(configuredToken))
            {
                logger.LogError("Webhook token is not configured on server.");
                return Results.Unauthorized();
            }
            
            if (tokenHeader.Length != configuredToken.Length || 
                !CryptographicOperations.FixedTimeEquals(
                    System.Text.Encoding.UTF8.GetBytes(tokenHeader),
                    System.Text.Encoding.UTF8.GetBytes(configuredToken)))
            {
                logger.LogWarning("Invalid webhook token.");
                return Results.Unauthorized();
            }

            try
            {
                using var document = await JsonDocument.ParseAsync(request.Body);
                var root = document.RootElement;
                
                var eventId = root.GetProperty("id").GetString();
                var eventType = root.GetProperty("event").GetString();
                
                if (string.IsNullOrEmpty(eventId) || string.IsNullOrEmpty(eventType))
                {
                    return Results.BadRequest("Missing id or event.");
                }

                var gatewayPaymentId = root.TryGetProperty("payment", out var paymentElem) && paymentElem.TryGetProperty("id", out var paymentId)
                    ? paymentId.GetString() : null;
                var gatewayCheckoutId = root.TryGetProperty("checkout", out var checkoutElem) && checkoutElem.TryGetProperty("id", out var checkoutId)
                    ? checkoutId.GetString() : null;
                if (gatewayPaymentId == null && gatewayCheckoutId == null) return Results.BadRequest("Missing payment or checkout.");

                var webhookEvent = new AsaasWebhookEvent
                {
                    Id = Guid.NewGuid(),
                    AsaasEventId = eventId,
                    EventType = eventType,
                    GatewayPaymentId = gatewayPaymentId,
                    GatewayCheckoutId = gatewayCheckoutId,
                    Payload = root.GetRawText(),
                    ReceivedAtUtc = DateTimeOffset.UtcNow,
                    Status = "Pending"
                };

                db.Add(webhookEvent);
                await db.SaveChangesAsync();

                return Results.Ok(new { success = true });
            }
            catch (DbUpdateException ex) when (ex.InnerException is PostgresException pg && pg.SqlState == PostgresErrorCodes.UniqueViolation)
            {
                // Verifica se é violação de Unique (duplicado)
                logger.LogInformation(ex, "DbUpdateException on webhook, possibly duplicate.");
                return Results.Ok(new { success = true, note = "duplicate ignored" });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error processing webhook.");
                return Results.Problem("Internal error processing webhook.");
            }
        }).WithTags("Webhooks").AllowAnonymous();
    }
}
