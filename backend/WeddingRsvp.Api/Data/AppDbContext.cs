using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Data;

/// <summary>
/// Contexto do Entity Framework Core.
/// Todas as queries são parametrizadas automaticamente pelo EF Core,
/// eliminando o risco de SQL Injection por design.
/// </summary>
public class AppDbContext : IdentityDbContext<AdminUser, IdentityRole<Guid>, Guid>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Rsvp> Rsvps => Set<Rsvp>();
    public DbSet<Gift> Gifts => Set<Gift>();
    public DbSet<GiftImage> GiftImages => Set<GiftImage>();
    public DbSet<GiftOrder> GiftOrders => Set<GiftOrder>();
    public DbSet<GiftOrderItem> GiftOrderItems => Set<GiftOrderItem>();
    public DbSet<PaymentAttempt> PaymentAttempts => Set<PaymentAttempt>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<AsaasWebhookEvent> AsaasWebhookEvents => Set<AsaasWebhookEvent>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<AppSetting> AppSettings => Set<AppSetting>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<Rsvp>(entity =>
        {
            if (Database.IsRelational())
            {
                entity.ToTable("rsvps");
            }
            entity.HasKey(e => e.Id);

            // Limites de tamanho reforçados no banco (dupla camada de proteção)
            entity.Property(e => e.Nome)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.Email)
                .IsRequired()
                .HasMaxLength(254);

            entity.Property(e => e.Telefone)
                .IsRequired()
                .HasMaxLength(20);

            entity.Property(e => e.Observacoes)
                .HasMaxLength(500);

            // Índice único em Email: garante que cada pessoa confirme apenas uma vez
            var index = entity.HasIndex(e => e.Email)
                .IsUnique();

            if (Database.IsRelational())
            {
                index.HasDatabaseName("ix_rsvps_email");
            }

            // Timestamp gerado com precisão UTC pelo PostgreSQL
            if (Database.IsRelational())
            {
                entity.Property(e => e.CriadoEm)
                    .HasDefaultValueSql("NOW()");
            }
        });

        modelBuilder.Entity<Gift>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("gifts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(150);
            entity.Property(e => e.Slug).IsRequired().HasMaxLength(150);
            entity.HasIndex(e => e.Slug).IsUnique();
            entity.HasIndex(e => new { e.Active, e.Category, e.DisplayOrder });
            entity.Property(e => e.Version).IsConcurrencyToken();
        });

        modelBuilder.Entity<GiftImage>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("gift_images");
            entity.HasKey(e => e.Id);
            entity.HasOne(e => e.Gift).WithMany(g => g.Images).HasForeignKey(e => e.GiftId).OnDelete(DeleteBehavior.Restrict);
            // PostgreSQL: partial index format
            if (Database.IsRelational())
            {
                entity.HasIndex(e => new { e.GiftId, e.IsPrimary }).IsUnique().HasFilter("\"IsPrimary\" = true");
            }
        });

        modelBuilder.Entity<GiftOrder>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("gift_orders");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Version).IsConcurrencyToken();
            entity.HasIndex(e => e.PublicTokenHash);
        });

        modelBuilder.Entity<GiftOrderItem>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("gift_order_items");
            entity.HasKey(e => e.Id);
            entity.HasOne(e => e.Order).WithMany(o => o.Items).HasForeignKey(e => e.OrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.Gift).WithMany().HasForeignKey(e => e.GiftId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<PaymentAttempt>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("payment_attempts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Version).IsConcurrencyToken();
            entity.HasOne(e => e.Order).WithMany().HasForeignKey(e => e.OrderId).OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(e => e.IdempotencyKey).IsUnique();
            entity.HasIndex(e => e.GatewayCheckoutId).IsUnique();
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("payments");
            entity.HasKey(e => e.Id);

            entity.HasOne(e => e.Order).WithMany().HasForeignKey(e => e.OrderId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(e => e.Attempt).WithMany().HasForeignKey(e => e.AttemptId).OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(e => new { e.Gateway, e.Environment, e.GatewayPaymentId }).IsUnique();
        });

        modelBuilder.Entity<AsaasWebhookEvent>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("asaas_webhook_events");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.AsaasEventId).IsUnique();
            entity.HasIndex(e => new { e.Status, e.NextAttemptAtUtc });
        });

        modelBuilder.Entity<AuditLog>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("audit_logs");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.TimestampUtc, e.UserId, e.Action, e.EntityType });
        });

        modelBuilder.Entity<AppSetting>(entity =>
        {
            if (Database.IsRelational()) entity.ToTable("app_settings");
            entity.HasKey(e => e.Key);
            entity.Property(e => e.Key).HasMaxLength(100);
        });
    }
}
