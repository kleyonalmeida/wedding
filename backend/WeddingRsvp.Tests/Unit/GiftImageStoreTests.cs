using Microsoft.Extensions.Configuration;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using WeddingRsvp.Api.Services;
using Xunit;

namespace WeddingRsvp.Tests.Unit;

public class GiftImageStoreTests
{
    [Fact]
    public async Task EnsureThumbnailsAsync_ReplacesIncompleteThumbnailAndPreservesAspectRatio()
    {
        var directory = Path.Combine(Path.GetTempPath(), "wedding-thumb-test-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        try
        {
            var store = new GiftImageStore(new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string?> { ["GiftImagePath"] = directory })
                .Build());
            const string key = "existing.webp";
            using (var original = new Image<Rgba32>(1000, 500))
                await original.SaveAsWebpAsync(store.PathFor(key));
            await File.WriteAllTextAsync(store.PathForThumb(key), "incomplete");

            await store.EnsureThumbnailsAsync();

            using var thumbnail = await Image.LoadAsync(store.PathForThumb(key));
            Assert.Equal(480, thumbnail.Width);
            Assert.Equal(240, thumbnail.Height);
        }
        finally
        {
            Directory.Delete(directory, recursive: true);
        }
    }
}
