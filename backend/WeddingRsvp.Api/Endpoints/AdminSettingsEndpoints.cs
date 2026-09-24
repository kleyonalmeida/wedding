using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminSettingsEndpoints
{
    public static void MapAdminSettingsEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/settings")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        group.MapGet("/", async (AppDbContext dbContext) =>
        {
            var settings = await dbContext.AppSettings.ToListAsync();
            return Results.Ok(settings.Select(s => new
            {
                s.Key,
                s.Value,
                s.Revision,
                s.UpdatedAtUtc
            }));
        });

        group.MapPatch("/", async (
            [FromBody] PatchSettingsRequest request,
            AppDbContext dbContext,
            IAuditService auditService,
            ClaimsPrincipal user) =>
        {
            if (request.Settings == null || !request.Settings.Any())
            {
                return Results.BadRequest(new { message = "Nenhuma configuração fornecida." });
            }

            var userIdString = user.FindFirstValue(ClaimTypes.NameIdentifier);
            Guid? userId = userIdString != null ? Guid.Parse(userIdString) : null;

            var keys = request.Settings.Select(s => s.Key).ToList();
            var existingSettings = await dbContext.AppSettings
                .Where(s => keys.Contains(s.Key))
                .ToDictionaryAsync(s => s.Key);

            foreach (var reqSetting in request.Settings)
            {
                if (existingSettings.TryGetValue(reqSetting.Key, out var setting))
                {
                    var oldValues = new { setting.Value };
                    var newValues = new { Value = reqSetting.Value };

                    setting.Value = reqSetting.Value;
                    setting.Revision++;
                    setting.AuthorUserId = userId;
                    setting.UpdatedAtUtc = DateTimeOffset.UtcNow;

                    await auditService.LogAsync("UpdateSetting", "AppSetting", setting.Key, "Configuração atualizada", oldValues, newValues);
                }
                else
                {
                    var newSetting = new AppSetting
                    {
                        Key = reqSetting.Key,
                        Value = reqSetting.Value,
                        Revision = 1,
                        AuthorUserId = userId,
                        UpdatedAtUtc = DateTimeOffset.UtcNow
                    };
                    dbContext.AppSettings.Add(newSetting);
                    
                    var newValues = new { newSetting.Value };
                    await auditService.LogAsync("CreateSetting", "AppSetting", newSetting.Key, "Configuração criada", null, newValues);
                }
            }

            await dbContext.SaveChangesAsync();
            return Results.Ok(new { message = "Configurações atualizadas com sucesso." });
        });
    }
}

public class PatchSettingsRequest
{
    public List<SettingItem> Settings { get; set; } = new();
}

public class SettingItem
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}
