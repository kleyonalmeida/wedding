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
// JWT AUTHENTICATION
// ════════════════════════════════════════════════════════════════════════════
var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException("Jwt:Secret não configurado.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException("Jwt:Issuer não configurado.");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = jwtIssuer,
            ValidAudience            = jwtIssuer,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            // Sem tolerância de clock — token expirado é imediatamente inválido
            ClockSkew                = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// ════════════════════════════════════════════════════════════════════════════
// CORS — Política restrita
// Apenas a origem do Flutter Web pode fazer requisições cross-origin.
// Configure a variável de ambiente ALLOWED_ORIGIN no servidor.
// ════════════════════════════════════════════════════════════════════════════
var allowedOrigin = builder.Configuration["AllowedOrigin"]
    ?? throw new InvalidOperationException("AllowedOrigin não configurado.");

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWebPolicy", policy =>
        policy
            .WithOrigins(allowedOrigin)
            .WithMethods("GET", "POST", "OPTIONS")
            .WithHeaders("Content-Type", "Authorization")
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

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

// ════════════════════════════════════════════════════════════════════════════
// SWAGGER / OPENAPI — Apenas em Development
// ════════════════════════════════════════════════════════════════════════════
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Wedding RSVP API", Version = "v1" });

    // Adiciona suporte a JWT no Swagger UI
    c.AddSecurityDefinition("Bearer", new()
    {
        Type        = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme      = "bearer",
        BearerFormat = "JWT",
        Description = "Insira o token JWT obtido via POST /api/admin/login"
    });
    c.AddSecurityRequirement(new()
    {
        {
            new() { Reference = new() { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
});

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
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Wedding RSVP API v1"));
}

app.UseCors("FlutterWebPolicy");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

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
}

// ════════════════════════════════════════════════════════════════════════════
// ENDPOINTS
// ════════════════════════════════════════════════════════════════════════════
app.MapHealthChecks("/healthz");

// RSVP público — rate limiting aplicado dentro do grupo de endpoints
app.MapRsvpEndpoints("RsvpPolicy");

// Admin — rate limiting próprio aplicado dentro do grupo
app.MapAdminEndpoints("AdminPolicy");

app.Run();

// Necessário para testes de integração (WebApplicationFactory)
public partial class Program 
{
    public static bool IsTesting { get; set; } = false;
}
