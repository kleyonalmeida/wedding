using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Entities;

namespace WeddingRsvp.Api.Data;

public static class DbSeeder
{
    public static async Task SeedGiftsAsync(AppDbContext db)
    {
        if (await db.Gifts.AnyAsync())
            return;

        var gifts = new[]
        {
            new Gift
            {
                Id = Guid.NewGuid(),
                Name = "Cota de Lua de Mel",
                ShortDescription = "Ajude na nossa viagem dos sonhos",
                Description = "Cota de lua de mel para curtirmos as Ilhas Maldivas",
                PriceCents = 50000,
                Category = "Viagem",
                Slug = "cota-lua-de-mel-500",
                Active = true,
                Featured = true,
                DisplayOrder = 1,
                CreatedAtUtc = DateTimeOffset.UtcNow
            },
            new Gift
            {
                Id = Guid.NewGuid(),
                Name = "Jantar Romântico",
                ShortDescription = "Um jantar inesquecível",
                Description = "Cota para nosso primeiro jantar oficial como casados",
                PriceCents = 25000,
                Category = "Experiência",
                Slug = "jantar-romantico",
                Active = true,
                Featured = true,
                DisplayOrder = 2,
                CreatedAtUtc = DateTimeOffset.UtcNow
            },
            new Gift
            {
                Id = Guid.NewGuid(),
                Name = "Passeio de Barco",
                ShortDescription = "Passeio pelas ilhas",
                Description = "Ajude a financiar nosso passeio turístico na lua de mel",
                PriceCents = 15000,
                Category = "Experiência",
                Slug = "passeio-barco",
                Active = true,
                Featured = false,
                DisplayOrder = 3,
                CreatedAtUtc = DateTimeOffset.UtcNow
            },
            new Gift
            {
                Id = Guid.NewGuid(),
                Name = "Brinde com Champagne",
                ShortDescription = "Saúde aos noivos!",
                Description = "Um brinde especial durante nossa viagem",
                PriceCents = 10000,
                Category = "Experiência",
                Slug = "brinde-champagne",
                Active = true,
                Featured = false,
                DisplayOrder = 4,
                CreatedAtUtc = DateTimeOffset.UtcNow
            }
        };

        db.Gifts.AddRange(gifts);
        await db.SaveChangesAsync();
    }
}
