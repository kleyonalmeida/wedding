using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Services;

public static class AdminSeedService
{
    private static readonly SemaphoreSlim _semaphore = new SemaphoreSlim(1, 1);

    public static async Task SeedSuperAdminAsync(IServiceProvider serviceProvider, IConfiguration configuration)
    {
        await _semaphore.WaitAsync();
        try
        {
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
            var userManager = serviceProvider.GetRequiredService<UserManager<AdminUser>>();

            var roleName = "SuperAdmin";
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                var result = await roleManager.CreateAsync(new IdentityRole<Guid>(roleName));
                if (!result.Succeeded)
                    throw new InvalidOperationException("Não foi possível criar a função SuperAdmin.");
            }

            var isTesting = Program.IsTesting;
            var adminEmail = configuration["SUPERADMIN_EMAIL"] ?? (isTesting ? "admin@wedding.com" : null);
            var adminPassword = configuration["SUPERADMIN_INITIAL_PASSWORD"] ?? (isTesting ? "Admin@123!" : null);
            if (string.IsNullOrWhiteSpace(adminEmail))
                throw new InvalidOperationException("SUPERADMIN_EMAIL é obrigatório.");

            var existingUsers = await userManager.Users.Where(u => u.Email == adminEmail).ToListAsync();
            var existingUser = existingUsers.FirstOrDefault();
            if (existingUser == null)
            {
                if (string.IsNullOrWhiteSpace(adminPassword))
                    throw new InvalidOperationException("SUPERADMIN_INITIAL_PASSWORD é obrigatório no primeiro início.");
                var adminUser = new AdminUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    EmailConfirmed = true,
                    MustChangePassword = true
                };

                var result = await userManager.CreateAsync(adminUser, adminPassword);
                if (!result.Succeeded) throw new InvalidOperationException("Não foi possível criar o SuperAdmin inicial: " + string.Join(", ", result.Errors.Select(e => e.Code)));
                var roleResult = await userManager.AddToRoleAsync(adminUser, roleName);
                if (!roleResult.Succeeded) throw new InvalidOperationException("Não foi possível atribuir a função SuperAdmin.");
            }
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
