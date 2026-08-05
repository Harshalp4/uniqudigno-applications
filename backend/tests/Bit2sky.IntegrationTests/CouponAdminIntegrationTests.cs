using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// Admin coupon CRUD: create → list → update → delete, plus a permission gate.
public class CouponAdminIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public CouponAdminIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    private HttpClient Client(params string[] permissions)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "admin");
        using var scope = _factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var (token, _) = jwt.IssueAccessToken(Guid.NewGuid(), "super_admin", permissions, "admin-portal");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    private static object SamplePayload(string code) => new
    {
        code,
        description = "Integration test",
        type = "Percentage",
        value = 15,
        maxDiscount = 200,
        minOrderValue = 500,
        totalUsageLimit = 100,
        perUserLimit = 1,
        validFrom = (DateTimeOffset?)null,
        validUntil = (DateTimeOffset?)null,
        isActive = true,
    };

    [Fact]
    public async Task Coupon_CreateListUpdateDelete_Roundtrips()
    {
        var client = Client("coupons.view", "coupons.create", "coupons.update", "coupons.delete");
        var code = "TESTCRUD" + Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();

        // Create
        var create = await client.PostAsJsonAsync("/api/v1/admin/coupons", SamplePayload(code));
        Assert.Equal(HttpStatusCode.OK, create.StatusCode);
        var created = JsonDocument.Parse(await create.Content.ReadAsStringAsync())
            .RootElement.GetProperty("data");
        var id = created.GetProperty("id").GetString();
        Assert.False(string.IsNullOrEmpty(id));

        // List contains it
        var list = await client.GetAsync("/api/v1/admin/coupons");
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);
        Assert.Contains(code, await list.Content.ReadAsStringAsync());

        // Update value
        var update = await client.PutAsJsonAsync($"/api/v1/admin/coupons/{id}", SamplePayload(code));
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);

        // Delete
        var del = await client.DeleteAsync($"/api/v1/admin/coupons/{id}");
        Assert.Equal(HttpStatusCode.OK, del.StatusCode);
    }

    [Fact]
    public async Task Coupon_Create_WithoutPermission_Returns403()
    {
        var client = Client("coupons.view"); // no create
        var res = await client.PostAsJsonAsync("/api/v1/admin/coupons", SamplePayload("NOPERM01"));
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }
}
