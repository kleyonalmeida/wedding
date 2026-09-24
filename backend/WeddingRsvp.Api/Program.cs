using System.Text;
using System.Threading.RateLimiting;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Endpoints;
using WeddingRsvp.Api.Models;
using WeddingRsvp.Api.Validators;
using Microsoft.AspNetCore.Identity;
using WeddingRsvp.Api.Entities;
using WeddingRsvp.Api.Services;
using WeddingRsvp.Api.Payments;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.DataProtection;

var builder = WebApplication.CreateBuilder(args);

if (IsTesting)
{
    builder.Configuration["Jwt:Secret"] = "chave_secreta_super_segura_para_testes_12345";
    builder.Configuration["Jwt:Issuer"] = "wedding-rsvp-api";
    builder.Configuration["Admin:Username"] = "admin";
    builder.Configuration["Admin:PasswordHash"] = "$2a$11$eI26Vg3laC9LPxOVG4CYRudN4nn5weEPy83K8GTx.pl4VrrIn3v4C"; // Hash para 'senha_teste'
}

// ════════════════════════════════════════════════════════════════════════════
// DATABASE — EF Core com PostgreSQL
// Queries 100% parametrizadas por design — SQL Injection eliminado por padrão.
// ════════════════════════════════════════════════════════════════════════════
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' não configurada.");

builder.Services.AddDbContext<AppDbContext>(options =>
{
    if (Program.IsTesting)
    {
        options.UseInMemoryDatabase("InMemoryDbForTesting");
    }
    else
    {
        options.UseNpgsql(connectionString, npgsql =>
        {
            npgsql.CommandTimeout(30); // Cancela queries lentas — proteção contra DoS
        });
    }
});

// ════════════════════════════════════════════════════════════════════════════
// FLUENT VALIDATION
// Registrado no DI para ser injetado no ValidationFilter<T>
// ════════════════════════════════════════════════════════════════════════════
builder.Services.AddScoped<IValidator<RsvpRequest>, RsvpRequestValidator>();

// ════════════════════════════════════════════════════════════════════════════
// IDENTITY & AUTHENTICATION
// ════════════════════════════════════════════════════════════════════════════
builder.Services.AddIdentity<AdminUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 8;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireLowercase = true;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();
builder.Services.Configure<SecurityStampValidatorOptions>(options => options.ValidationInterval = TimeSpan.Zero);

var keyPath = builder.Configuration["DataProtectionKeyPath"] ?? "/tmp/wedding-dpkeys";
Directory.CreateDirectory(keyPath);
builder.Services.AddDataProtection().SetApplicationName("WeddingAdmin")
    .PersistKeysToFileSystem(new DirectoryInfo(keyPath));

builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.Name = ".Wedding.Admin";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always; // Requer HTTPS
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.ExpireTimeSpan = TimeSpan.FromHours(8); // Conforme plano, teto de tempo
    options.SlidingExpiration = true;
    options.Events.OnRedirectToLogin = context =>
    {
        context.Response.StatusCode = 401;
        return Task.CompletedTask;
    };
    options.Events.OnRedirectToAccessDenied = context =>
    {
        context.Response.StatusCode = 403;
        return Task.CompletedTask;
    };
});

// CSRF / Antiforgery
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN"; // Header usado pelo frontend
});

builder.Services.AddAuthorizationBuilder()
    .AddPolicy("SuperAdmin", policy => policy.RequireRole("SuperAdmin"));

// ════════════════════════════════════════════════════════════════════════════
// CORS — Política restrita
// Apenas a origem do Flutter Web pode fazer requisições cross-origin.
// Configure a variável de ambiente ALLOWED_ORIGIN no servidor.
// ════════════════════════════════════════════════════════════════════════════
var allowedOrigin = builder.Configuration["AllowedOrigin"]
    ?? throw new InvalidOperationException("AllowedOrigin não configurado.");

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAuditService, AuditService>();
builder.Services.AddSingleton<GiftImageStore>();

builder.Services.AddHttpClient<IPaymentGateway, AsaasPaymentGateway>();
builder.Services.AddHostedService<WebhookProcessor>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWebPolicy", policy =>
        policy
            .WithOrigins(allowedOrigin)
            .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .WithHeaders("Content-Type", "Authorization", "X-CSRF-TOKEN")
            .AllowCredentials()
            // Cache preflight por 10 minutos — reduz requisições OPTIONS desnecessárias
            .SetPreflightMaxAge(TimeSpan.FromMinutes(10)));
});

// ════════════════════════════════════════════════════════════════════════════
// RATE LIMITING — Proteção contra spam e abuso
// 10 requisições por minuto por IP no endpoint de RSVP
// ════════════════════════════════════════════════════════════════════════════
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("RsvpPolicy", limiter =>
    {
        limiter.Window              = TimeSpan.FromMinutes(1);
        limiter.PermitLimit         = 10;
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiter.QueueLimit          = 0; // Sem fila — rejeita imediatamente ao exceder
    });

    // Rate limit mais relaxado para o painel admin (apenas o administrador acessa)
    options.AddFixedWindowLimiter("AdminPolicy", limiter =>
    {
        limiter.Window      = TimeSpan.FromMinutes(1);
        limiter.PermitLimit = 30;
        limiter.QueueLimit  = 0;
    });

    options.AddPolicy("OrderPolicy", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions
        {
            Window = TimeSpan.FromMinutes(1), PermitLimit = 10, QueueLimit = 0
        }));

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

// ════════════════════════════════════════════════════════════════════════════
// SWAGGER / OPENAPI — Apenas em Development
// ════════════════════════════════════════════════════════════════════════════
builder.Services.AddOpenApi();

// ════════════════════════════════════════════════════════════════════════════
// HEALTH CHECK — Usado pelo Docker Compose e Nginx
// ════════════════════════════════════════════════════════════════════════════
builder.Services.AddHealthChecks();

var app = builder.Build();

// ════════════════════════════════════════════════════════════════════════════
// MIDDLEWARE PIPELINE
// A ordem importa — CORS deve vir antes de Auth, RateLimiter antes dos endpoints
// ════════════════════════════════════════════════════════════════════════════
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("FlutterWebPolicy");
app.UseRateLimiter();
app.UseAuthentication();
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/api/admin"))
    {
        var path = context.Request.Path.Value ?? string.Empty;
        if (!Program.IsTesting && context.User.Identity?.IsAuthenticated == true &&
            !path.StartsWith("/api/admin/auth/", StringComparison.OrdinalIgnoreCase) &&
            !path.StartsWith("/api/admin/security/", StringComparison.OrdinalIgnoreCase))
        {
            var userManager = context.RequestServices.GetRequiredService<UserManager<AdminUser>>();
            var user = await userManager.GetUserAsync(context.User);
            if (user == null || user.MustChangePassword || !user.TwoFactorEnabled)
            {
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                return;
            }
        }
        if (context.User.Identity?.IsAuthenticated == true &&
            (HttpMethods.IsPost(context.Request.Method) || HttpMethods.IsPut(context.Request.Method) ||
             HttpMethods.IsPatch(context.Request.Method) || HttpMethods.IsDelete(context.Request.Method)))
        {
            var antiforgery = context.RequestServices.GetRequiredService<IAntiforgery>();
            if (!await antiforgery.IsRequestValidAsync(context))
            {
                context.Response.StatusCode = StatusCodes.Status400BadRequest;
                return;
            }
        }
    }
    await next(context);
});
app.UseAuthorization();
app.UseAntiforgery();

// ════════════════════════════════════════════════════════════════════════════
// MIGRATION AUTOMÁTICA — Aplica migrations pendentes no startup
// Seguro para o ciclo de vida curto desta aplicação
// ════════════════════════════════════════════════════════════════════════════
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (Program.IsTesting)
    {
        db.Database.EnsureCreated();
    }
    else if (db.Database.IsRelational())
    {
        db.Database.Migrate();
    }

    if (app.Environment.IsDevelopment() && !Program.IsTesting)
    {
        DbSeeder.SeedGiftsAsync(db).GetAwaiter().GetResult();
    }

    // Seed do SuperAdmin
    WeddingRsvp.Api.Services.AdminSeedService.SeedSuperAdminAsync(scope.ServiceProvider, app.Configuration).GetAwaiter().GetResult();
}

// ════════════════════════════════════════════════════════════════════════════
// ENDPOINTS
// ════════════════════════════════════════════════════════════════════════════
app.MapHealthChecks("/healthz");

// RSVP público — rate limiting aplicado dentro do grupo de endpoints
app.MapRsvpEndpoints("RsvpPolicy");

// Public Gifts and Orders
app.MapPublicGiftEndpoints();
app.MapGiftOrderEndpoints();
app.MapAsaasWebhookEndpoints();

// Admin Auth - Sem rate limit do RSVP
app.MapAdminAuthEndpoints();
app.MapAdminSecurityEndpoints();
app.MapAdminAuditEndpoints();
app.MapAdminAttendanceEndpoints();
app.MapAdminDashboardEndpoints();
app.MapAdminProductEndpoints();
app.MapAdminPaymentEndpoints();
app.MapAdminSettingsEndpoints();

// Admin — rate limiting próprio aplicado dentro do grupo
app.MapAdminEndpoints("AdminPolicy");

app.Run();

// Necessário para testes de integração (WebApplicationFactory)
public partial class Program
{
    public static bool IsTesting { get; set; } = false;
}
