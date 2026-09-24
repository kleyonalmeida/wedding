using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Entities;
using Xunit;

namespace WeddingRsvp.Tests.Integration.Database;

public class GiftEntityTests
{
    private AppDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        
        return new AppDbContext(options);
    }

    [Fact]
    public async Task Deve_Adicionar_E_Recuperar_Gift()
    {
        using var db = CreateDbContext();
        var gift = new Gift
        {
            Id = Guid.NewGuid(),
            Name = "Geladeira",
            PriceCents = 350000,
            Category = "Cozinha",
            Slug = "geladeira-brastemp",
            Active = true,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        db.Gifts.Add(gift);
        await db.SaveChangesAsync();

        var retrievedGift = await db.Gifts.FirstOrDefaultAsync(g => g.Slug == "geladeira-brastemp");

        Assert.NotNull(retrievedGift);
        Assert.Equal("Geladeira", retrievedGift.Name);
    }
}
