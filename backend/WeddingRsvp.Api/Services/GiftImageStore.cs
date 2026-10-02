using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

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
        if (image.Length == 0 || image.Length > 10 * 1024 * 1024)
            throw new ArgumentException("A imagem deve ter até 10 MiB.");
        if (image.ContentType is not ("image/jpeg" or "image/png" or "image/webp" or "application/octet-stream"))
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
        var thumbPath = Path.Combine(_directory, "thumb_" + key);
        try
        {
            await using (var output = File.Create(path))
                await bitmap.SaveAsWebpAsync(output, cancellationToken);

            await WriteThumbnailAsync(bitmap, thumbPath, cancellationToken);

            return (key, "image/webp", new FileInfo(path).Length, bitmap.Width, bitmap.Height);
        }
        catch
        {
            DeleteArtifacts(key);
            throw;
        }
    }

    public string PathFor(string key)
    {
        if (Path.GetFileName(key) != key || key.Contains("..")) throw new ArgumentException("Invalid image key.");
        return Path.Combine(_directory, key);
    }

    public string PathForThumb(string key)
    {
        if (Path.GetFileName(key) != key || key.Contains("..")) throw new ArgumentException("Invalid image key.");
        return Path.Combine(_directory, "thumb_" + key);
    }

    public void DeleteArtifacts(string key)
    {
        File.Delete(PathFor(key));
        File.Delete(PathForThumb(key));
    }

    public async Task EnsureThumbnailsAsync(CancellationToken cancellationToken = default)
    {
        if (!Directory.Exists(_directory)) return;

        var files = Directory.GetFiles(_directory, "*.webp");
        foreach (var file in files)
        {
            var fileName = Path.GetFileName(file);
            if (fileName.StartsWith("thumb_")) continue;

            var thumbPath = PathForThumb(fileName);
            if (await IsValidThumbnailAsync(thumbPath, cancellationToken)) continue;

            try
            {
                using var image = await Image.LoadAsync(file, cancellationToken);
                await WriteThumbnailAsync(image, thumbPath, cancellationToken);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch
            {
                // Um arquivo inválido não pode bloquear a próxima tentativa.
                try { File.Delete(thumbPath); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            }
        }
    }

    private static async Task<bool> IsValidThumbnailAsync(string path, CancellationToken cancellationToken)
    {
        if (!File.Exists(path)) return false;
        try
        {
            using var image = await Image.LoadAsync(path, cancellationToken);
            return image.Width <= 480 && image.Height <= 480;
        }
        catch (UnknownImageFormatException) { return false; }
        catch (InvalidImageContentException) { return false; }
        catch (IOException) { return false; }
        catch (UnauthorizedAccessException) { return false; }
    }

    private static async Task WriteThumbnailAsync(Image source, string path, CancellationToken cancellationToken)
    {
        var temporaryPath = path + ".tmp." + Guid.NewGuid().ToString("N");
        try
        {
            using var thumbnail = source.Clone(context =>
            {
                if (source.Width > 480 || source.Height > 480)
                    context.Resize(new ResizeOptions
                    {
                        Mode = ResizeMode.Max,
                        Size = new Size(480, 480)
                    });
            });
            await using (var output = File.Create(temporaryPath))
                await thumbnail.SaveAsWebpAsync(output, cancellationToken);
            File.Move(temporaryPath, path, overwrite: true);
        }
        finally
        {
            File.Delete(temporaryPath);
        }
    }
}
