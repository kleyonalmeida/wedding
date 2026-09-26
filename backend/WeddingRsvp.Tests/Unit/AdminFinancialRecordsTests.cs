using Microsoft.EntityFrameworkCore;
using WeddingRsvp.Api.Data;
using WeddingRsvp.Api.Services;

namespace WeddingRsvp.Tests.Unit;

public class AdminFinancialRecordsTests
{
    [Fact]
    public void LedgerCanBeTranslatedByPostgresWithPaginationAndFilters()
    {
        using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=translation_only;Username=test;Password=test")
            .Options);
        var query = AdminFinancialRecords.Query(db);
        var sql = query.OrderByDescending(p => p.CreatedAtUtc).ThenBy(p => p.Id)
            .Skip(20).Take(20).ToQueryString();
        Assert.Contains("UNION ALL", sql);
        Assert.Contains("NOT EXISTS", sql);
        Assert.Contains("LIMIT", sql);
        Assert.Contains("WHERE", query.Where(p => p.Status == "Confirmed").ToQueryString());
    }
}
