using System.Net;
using System.Net.Http.Json;
using WeddingRsvp.Api.Models;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using Xunit;

namespace WeddingRsvp.Tests.Integration;

public class AdminProductEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AdminProductEndpointsTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private async Task<HttpClient> GetAuthenticatedClientAsync(bool withCsrf = true)
    {
        var client = _factory.CreateClient();
        var request = new AdminLoginRequest("admin@wedding.com", "Admin@123!");
        var response = await client.PostAsJsonAsync("/api/admin/auth/login", request);
        
        var cookies = response.Headers.GetValues("Set-Cookie");
        var authCookie = cookies.FirstOrDefault(c => c.StartsWith(".Wedding.Admin"));
        if (authCookie != null)
        {
            client.DefaultRequestHeaders.Add("Cookie", authCookie.Split(';')[0]);
        }
        
        if (withCsrf) await CustomWebApplicationFactory.AddCsrfAsync(client);
        return client;
    }

    [Fact]
    public async Task GET_Products_Authenticated_ReturnsOk()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.GetAsync("/api/admin/products");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
    
    [Fact]
    public async Task POST_Product_WithoutCsrf_ReturnsBadRequest()
    {
        var client = await GetAuthenticatedClientAsync(withCsrf: false);
        var response = await client.PostAsJsonAsync("/api/admin/products", new { name = "No CSRF", slug = "no-csrf", priceCents = 100, category = "Teste" });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task POST_Product_Valid_CreatesProduct()
    {
        var client = await GetAuthenticatedClientAsync();
        var request = new 
        { 
            name = "Test Gift",
            slug = "test-gift-unique",
            priceCents = 15000,
            category = "Cotas"
        };
        
        var response = await client.PostAsJsonAsync("/api/admin/products", request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.Equal("Test Gift", json.GetProperty("name").GetString());
    }

    [Fact]
    public async Task POST_Product_WithoutUrl_GeneratesSlugAndKeepsStockOffPublicApi()
    {
        var client = await GetAuthenticatedClientAsync();
        var response = await client.PostAsJsonAsync("/api/admin/products", new
        {
            name = "Café especial", category = "Casa", priceCents = 2599,
            stockRemaining = 2, externalUrl = "https://example.com/cafe"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var adminGift = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var slug = adminGift.GetProperty("slug").GetString();
        Assert.StartsWith("cafe-especial-", slug);
        Assert.Equal(2, adminGift.GetProperty("stockRemaining").GetInt32());
        var publicGift = await client.GetFromJsonAsync<System.Text.Json.JsonElement>($"/api/gifts/{slug}");
        Assert.Equal(2599, publicGift.GetProperty("priceCents").GetInt64());
        Assert.False(publicGift.TryGetProperty("stockRemaining", out _));
        Assert.False(publicGift.TryGetProperty("externalUrl", out _));
    }

    [Fact]
    public async Task POST_Image_PublishesImageForGift()
    {
        var client = await GetAuthenticatedClientAsync();
        var create = await client.PostAsJsonAsync("/api/admin/products", new
        {
            name = "Gift with image", slug = "gift-image-unique", priceCents = 1000, category = "Casa"
        });
        create.EnsureSuccessStatusCode();
        var gift = await create.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var id = gift.GetProperty("id").GetString();
        using var bitmap = new Image<Rgba32>(2, 2);
        await using var bytes = new MemoryStream();
        await bitmap.SaveAsPngAsync(bytes);
        using var form = new MultipartFormDataContent();
        form.Add(new ByteArrayContent(bytes.ToArray()) { Headers = { ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("image/png") } }, "image", "gift.png");
        var upload = await client.PostAsync($"/api/admin/products/{id}/images", form);
        Assert.Equal(HttpStatusCode.Created, upload.StatusCode);
        var publicGift = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/gifts/gift-image-unique");
        var imageUrl = publicGift.GetProperty("imageUrl").GetString();
        Assert.NotNull(imageUrl);
        var imageResponse = await client.GetAsync(imageUrl);
        Assert.Equal(HttpStatusCode.OK, imageResponse.StatusCode);
        Assert.Equal("image/webp", imageResponse.Content.Headers.ContentType?.MediaType);
        using var replacementForm = new MultipartFormDataContent();
        replacementForm.Add(new ByteArrayContent(bytes.ToArray()) { Headers = { ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("image/png") } }, "image", "replacement.png");
        var replacement = await client.PostAsync($"/api/admin/products/{id}/images", replacementForm);
        Assert.Equal(HttpStatusCode.Created, replacement.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync(imageUrl)).StatusCode);
    }
}
