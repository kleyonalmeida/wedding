using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Data;

/// <summary>
/// Contexto do Entity Framework Core.
/// Todas as queries são parametrizadas automaticamente pelo EF Core,
/// eliminando o risco de SQL Injection por design.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Rsvp> Rsvps => Set<Rsvp>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
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
    }
}
