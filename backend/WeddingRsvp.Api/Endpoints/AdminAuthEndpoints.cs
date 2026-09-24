using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Models;
using Microsoft.AspNetCore.Antiforgery;

namespace WeddingRsvp.Api.Endpoints;

public static class AdminAuthEndpoints
{
    public static void MapAdminAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin/auth").RequireRateLimiting("AdminPolicy");

        group.MapGet("/csrf", (IAntiforgery antiforgery, HttpContext context) =>
        {
            var tokens = antiforgery.GetAndStoreTokens(context);
            return Results.Ok(new { token = tokens.RequestToken });
        });

        group.MapPost("/login", async (
            [FromBody] AdminLoginRequest request,
            SignInManager<AdminUser> signInManager,
            UserManager<AdminUser> userManager) =>
        {
            // O plano pede lockout
            var result = await signInManager.PasswordSignInAsync(
                request.Username,
                request.Password,
                isPersistent: false,
                lockoutOnFailure: true);

            if (result.Succeeded)
            {
                // Login com sucesso retorna OK e o cookie é definido pelo middleware do Identity
                return Results.Ok(new { message = "Logged in successfully" });
            }

            if (result.IsLockedOut)
            {
                return Results.Unauthorized();
            }

            if (result.RequiresTwoFactor)
            {
                // Retorna 200 com flag indicando necessidade de MFA
                // Neste caso o signInManager cria um cookie de 2FA
                return Results.Ok(new { requiresTwoFactor = true });
            }

            return Results.Unauthorized();
        });

        group.MapPost("/mfa/verify", async (MfaVerifyRequest request, SignInManager<AdminUser> signInManager) =>
        {
            if (string.IsNullOrWhiteSpace(request.Code)) return Results.BadRequest();
            var result = await signInManager.TwoFactorAuthenticatorSignInAsync(request.Code, false, false);
            return result.Succeeded ? Results.Ok(new { authenticated = true }) : Results.Unauthorized();
        });

        group.MapPost("/mfa/recovery", async (MfaVerifyRequest request, SignInManager<AdminUser> signInManager) =>
        {
            if (string.IsNullOrWhiteSpace(request.Code)) return Results.BadRequest();
            var result = await signInManager.TwoFactorRecoveryCodeSignInAsync(request.Code);
            return result.Succeeded ? Results.Ok(new { authenticated = true }) : Results.Unauthorized();
        });

        // Este endpoint também precisa de autorização e antiforgery (em métodos mutáveis)
        group.MapPost("/logout", async (SignInManager<AdminUser> signInManager) =>
        {
            await signInManager.SignOutAsync();
            return Results.Ok();
        }).RequireAuthorization();

        // AdminMe
        group.MapGet("/me", async (HttpContext context, UserManager<AdminUser> userManager) =>
        {
            var user = context.User;
            if (user.Identity?.IsAuthenticated == true)
            {
                var admin = await userManager.GetUserAsync(user);
                return Results.Ok(new
                {
                    username = user.Identity.Name,
                    mustChangePassword = admin?.MustChangePassword ?? true,
                    mfaEnabled = admin?.TwoFactorEnabled ?? false
                });
            }
            return Results.Unauthorized();
        }).RequireAuthorization();
    }
}

public record MfaVerifyRequest(string Code);
