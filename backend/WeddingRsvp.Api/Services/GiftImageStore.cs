using SixLabors.ImageSharp;

namespace WeddingRsvp.Api.Services;

public sealed class GiftImageStore
{
    private readonly string _directory;

    public GiftImageStore(IConfiguration configuration)
    {
        _directory = configuration["GiftImagePath"] ?? "/tmp/wedding-gift-images";
    }

    public async Task<(string Key, string MimeType, long Length, int Width, int Height)> SaveAsync(IFormFile image, CancellationToken cancellationToken)
    {
        if (image.Length == 0 || image.Length > 5 * 1024 * 1024)
            throw new ArgumentException("A imagem deve ter até 5 MiB.");
        if (image.ContentType is not ("image/jpeg" or "image/png" or "image/webp"))
            throw new ArgumentException("Envie uma imagem JPEG, PNG ou WebP válida.");
        await using var input = image.OpenReadStream();
        using var buffer = new MemoryStream();
        await input.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;
        Image decoded;
        try
        {
            var info = await Image.IdentifyAsync(buffer, cancellationToken);
            if (info == null || info.Width > 6000 || info.Height > 6000 ||
                (long)info.Width * info.Height > 20_000_000)
                throw new ArgumentException("A imagem excede as dimensões permitidas.");
            buffer.Position = 0;
            decoded = await Image.LoadAsync(buffer, cancellationToken);
        }
        catch (ImageFormatException) { throw new ArgumentException("Formato de imagem inválido."); }
        using var bitmap = decoded;
        bitmap.Metadata.ExifProfile = null;
        bitmap.Metadata.IccProfile = null;
        bitmap.Metadata.XmpProfile = null;
        var key = Guid.NewGuid().ToString("N") + ".webp";
        Directory.CreateDirectory(_directory);
        var path = Path.Combine(_directory, key);
        try
        {
            await using var output = File.Create(path);
            await bitmap.SaveAsWebpAsync(output, cancellationToken);
            return (key, "image/webp", new FileInfo(path).Length, bitmap.Width, bitmap.Height);
        }
        catch
        {
            File.Delete(path);
            throw;
        }
    }

    public string PathFor(string key)
    {
        if (Path.GetFileName(key) != key || key.Contains("..")) throw new ArgumentException("Invalid image key.");
        return Path.Combine(_directory, key);
    }
}
