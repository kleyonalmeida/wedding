using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using System.Text.Encodings.Web;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminSecurityEndpoints
{
    private const string AuthenticatorUriFormat = "otpauth://totp/{0}:{1}?secret={2}&issuer={0}&digits=6";

    public static void MapAdminSecurityEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/security")
            .RequireAuthorization("SuperAdmin").RequireRateLimiting("AdminPolicy");

        // MFA Enroll - Gerar chave para configurar aplicativo autenticador
        group.MapPost("/mfa/enroll", async (
            UserManager<AdminUser> userManager,
            UrlEncoder urlEncoder,
            HttpContext context) =>
        {
            var user = await userManager.GetUserAsync(context.User);
            if (user == null) return Results.Unauthorized();
            if (user.TwoFactorEnabled) return Results.Conflict(new { message = "MFA já está ativo." });

            // Reseta a chave para garantir que uma nova seja gerada se o usuário solicitar enroll
            await userManager.ResetAuthenticatorKeyAsync(user);
            var unformattedKey = await userManager.GetAuthenticatorKeyAsync(user);

            var email = await userManager.GetEmailAsync(user);
            
            // Format URI for QR Code
            var authenticatorUri = string.Format(
                AuthenticatorUriFormat,
                urlEncoder.Encode("WeddingAdmin"),
                urlEncoder.Encode(email!),
                unformattedKey);

            return Results.Ok(new
            {
                sharedKey = unformattedKey,
                authenticatorUri = authenticatorUri
            });
        });

        // Models serao criados depois no arquivo correto ou definidos inline (nao recomendado, mas ok pra MVP)
        // MFA Confirm - Confirma o PIN e ativa MFA
        group.MapPost("/mfa/confirm", async (
            [FromBody] MfaConfirmRequest request,
            UserManager<AdminUser> userManager,
            HttpContext context) =>
        {
            var user = await userManager.GetUserAsync(context.User);
            if (user == null) return Results.Unauthorized();
            if (user.TwoFactorEnabled) return Results.Conflict(new { message = "MFA já está ativo." });

            var isValid = await userManager.VerifyTwoFactorTokenAsync(
                user, userManager.Options.Tokens.AuthenticatorTokenProvider, request.Code);

            if (!isValid)
            {
                return Results.BadRequest(new { message = "Invalid code." });
            }

            await userManager.SetTwoFactorEnabledAsync(user, true);

            // Gera e retorna códigos de recuperação
            if (await userManager.CountRecoveryCodesAsync(user) == 0)
            {
                var recoveryCodes = await userManager.GenerateNewTwoFactorRecoveryCodesAsync(user, 10);
                await context.SignOutAsync(Microsoft.AspNetCore.Identity.IdentityConstants.ApplicationScheme);
                return Results.Ok(new { message = "MFA enabled; sign in again", recoveryCodes });
            }

            await context.SignOutAsync(Microsoft.AspNetCore.Identity.IdentityConstants.ApplicationScheme);
            return Results.Ok(new { message = "MFA enabled; sign in again" });
        });

        // Change Password
        group.MapPost("/password", async (
            [FromBody] ChangePasswordRequest request,
            UserManager<AdminUser> userManager,
            SignInManager<AdminUser> signInManager,
            HttpContext context) =>
        {
            var user = await userManager.GetUserAsync(context.User);
            if (user == null) return Results.Unauthorized();

            var result = await userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
            if (!result.Succeeded)
            {
                return Results.BadRequest(new { errors = result.Errors });
            }

            user.MustChangePassword = false;
            await userManager.UpdateAsync(user);

            // Revoca as sessoes trocando o security stamp
            await userManager.UpdateSecurityStampAsync(user);

            return Results.Ok(new { message = "Password changed successfully. Sessions revoked." });
        });

        // Revoke all sessions (except current one can be tricky, UpdateSecurityStampAsync revokes all)
        group.MapPost("/sessions/revoke", async (
            UserManager<AdminUser> userManager,
            HttpContext context) =>
        {
            var user = await userManager.GetUserAsync(context.User);
            if (user == null) return Results.Unauthorized();

            await userManager.UpdateSecurityStampAsync(user);
            return Results.Ok(new { message = "All sessions revoked." });
        });
    }
}

public record MfaConfirmRequest(string Code);
public record ChangePasswordRequest(string CurrentPassword, string NewPassword);
