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
            entity.ToTable("rsvps");
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
            entity.HasIndex(e => e.Email)
                .IsUnique()
                .HasDatabaseName("ix_rsvps_email");

            // Timestamp gerado com precisão UTC pelo PostgreSQL
            entity.Property(e => e.CriadoEm)
                .HasDefaultValueSql("NOW()");
        });
    }
}
