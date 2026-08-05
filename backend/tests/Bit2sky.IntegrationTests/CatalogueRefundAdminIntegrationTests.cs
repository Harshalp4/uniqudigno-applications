using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// Admin Tests catalogue CRUD + Refund queue: routing, authorization, envelope.
public class CatalogueRefundAdminIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public CatalogueRefundAdminIntegrationTests(TestWebAppFactory factory) => _factory = factory;

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

    private static object TestPayload(string name) => new
    {
        name,
        slug = (string?)null,
        shortDescription = "Integration test",
        mrp = 500,
        price = 399,
        sampleType = "Blood",
        fastingRequired = true,
        homeCollectionAvailable = true,
        isPopular = false,
        isActive = true,
    };

    [Fact]
    public async Task Test_CreateUpdateDeactivate_Roundtrips()
    {
        var client = Client("tests.view", "tests.create", "tests.update", "tests.delete");
        var name = "Lipid Panel " + Guid.NewGuid().ToString("N")[..6];

        var create = await client.PostAsJsonAsync("/api/v1/admin/tests", TestPayload(name));
        Assert.Equal(HttpStatusCode.OK, create.StatusCode);
        var id = JsonDocument.Parse(await create.Content.ReadAsStringAsync())
            .RootElement.GetProperty("data").GetProperty("id").GetString();
        Assert.False(string.IsNullOrEmpty(id));

        var update = await client.PutAsJsonAsync($"/api/v1/admin/tests/{id}", TestPayload(name));
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);

        var deactivate = await client.DeleteAsync($"/api/v1/admin/tests/{id}");
        Assert.Equal(HttpStatusCode.OK, deactivate.StatusCode);

        // Deactivated test still appears in the admin list (includes inactive).
        var list = await client.GetAsync("/api/v1/admin/tests?page=1&pageSize=50");
        Assert.Contains(name, await list.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Test_Create_WithoutPermission_Returns403()
    {
        var res = await Client("tests.view").PostAsJsonAsync("/api/v1/admin/tests", TestPayload("NoPerm"));
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    [Fact]
    public async Task Refunds_List_WithPermission_Returns200()
    {
        var res = await Client("refunds.view").GetAsync("/api/v1/admin/refunds");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Refunds_Process_WithoutPermission_Returns403()
    {
        var res = await Client("refunds.view")
            .PutAsJsonAsync($"/api/v1/admin/refunds/{Guid.NewGuid()}/process", new { });
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }
}
