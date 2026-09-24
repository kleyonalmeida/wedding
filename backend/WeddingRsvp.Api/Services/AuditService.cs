using System.Text.Json;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Services;

public interface IAuditService
{
    Task LogAsync(
        string action,
        string entityType,
        string? entityId = null,
        string? description = null,
        object? oldValues = null,
        object? newValues = null,
        bool success = true);
}

public class AuditService : IAuditService
{
    private readonly AppDbContext _db;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditService(AppDbContext db, IHttpContextAccessor httpContextAccessor)
    {
        _db = db;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task LogAsync(
        string action,
        string entityType,
        string? entityId = null,
        string? description = null,
        object? oldValues = null,
        object? newValues = null,
        bool success = true)
    {
        var context = _httpContextAccessor.HttpContext;
        var userIdString = context?.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        Guid? userId = Guid.TryParse(userIdString, out var uid) ? uid : null;

        var log = new AuditLog
        {
            Id = Guid.NewGuid(),
            TimestampUtc = DateTimeOffset.UtcNow,
            UserId = userId,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            Description = description ?? string.Empty,
            OldValues = oldValues != null ? JsonSerializer.Serialize(oldValues) : null,
            NewValues = newValues != null ? JsonSerializer.Serialize(newValues) : null,
            IpAddress = context?.Connection.RemoteIpAddress?.ToString(),
            UserAgent = context?.Request.Headers["User-Agent"].ToString(),
            CorrelationId = context?.TraceIdentifier,
            Success = success
        };

        _db.AuditLogs.Add(log);
        // Não chamamos SaveChanges aqui obrigatoriamente se quisermos que participe da transação do caller.
        // Mas se for fire-and-forget ou transação própria, precisamos de um mecanismo.
        // Por hora, apenas adiciona no ChangeTracker do escopo atual.
        // O ideal é salvar, pois se o caller falhar, o log de auditoria também é desfeito, 
        // ou criar um novo escopo para garantir o log mesmo em caso de falha.
        // Assumimos que o caller dará SaveChangesAsync se for transacional.
    }
}
