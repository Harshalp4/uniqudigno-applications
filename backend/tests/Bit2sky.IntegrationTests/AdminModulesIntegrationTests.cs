using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// The five admin modules completing the portal: packages, config, AI prompts,
// notifications, support, analytics. Verifies routing, per-action RBAC, envelope.
public class AdminModulesIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public AdminModulesIntegrationTests(TestWebAppFactory factory) => _factory = factory;

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

    // ── Packages CRUD ─────────────────────────────────────────────────────────
    private static object PackagePayload(string name) => new
    {
        name,
        slug = (string?)null,
        shortDescription = "Full body checkup",
        description = "Comprehensive panel",
        mrp = 2000,
        price = 1499,
        testCount = 60,
        parameterCount = 72,
        fastingRequired = true,
        reportTimeText = "within 24 hrs",
        isPopular = true,
        isFeatured = false,
        isActive = true,
    };

    [Fact]
    public async Task Packages_CreateUpdateDeactivate_Roundtrips()
    {
        var client = Client("packages.view", "packages.create", "packages.update", "packages.delete");
        var name = "Wellness Pack " + Guid.NewGuid().ToString("N")[..6];

        var create = await client.PostAsJsonAsync("/api/v1/admin/packages", PackagePayload(name));
        Assert.Equal(HttpStatusCode.OK, create.StatusCode);
        var id = JsonDocument.Parse(await create.Content.ReadAsStringAsync())
            .RootElement.GetProperty("data").GetProperty("id").GetString();
        Assert.False(string.IsNullOrEmpty(id));

        var update = await client.PutAsJsonAsync($"/api/v1/admin/packages/{id}", PackagePayload(name));
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);

        var deactivate = await client.DeleteAsync($"/api/v1/admin/packages/{id}");
        Assert.Equal(HttpStatusCode.OK, deactivate.StatusCode);

        var list = await client.GetAsync("/api/v1/admin/packages?page=1&pageSize=50");
        Assert.Contains(name, await list.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Packages_Create_WithoutPermission_Returns403()
    {
        var res = await Client("packages.view").PostAsJsonAsync("/api/v1/admin/packages", PackagePayload("NoPerm"));
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    // ── App Config ────────────────────────────────────────────────────────────
    [Fact]
    public async Task Config_ListAndUpdate_Roundtrips()
    {
        var client = Client("config.view", "config.update");
        var key = "test.flag." + Guid.NewGuid().ToString("N")[..6];

        var update = await client.PutAsJsonAsync($"/api/v1/admin/config/{key}", new { value = "on" });
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);

        var list = await client.GetAsync("/api/v1/admin/config");
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);
        Assert.Contains(key, await list.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Config_List_WithoutPermission_Returns403()
    {
        var res = await Client("users.view").GetAsync("/api/v1/admin/config");
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    // ── AI Prompts ────────────────────────────────────────────────────────────
    [Fact]
    public async Task AiPrompts_CreateThenActivate_Roundtrips()
    {
        var creator = Client("ai_prompts.view", "ai_prompts.create", "ai_prompts.activate");
        var name = "Copilot " + Guid.NewGuid().ToString("N")[..6];

        var create = await creator.PostAsJsonAsync("/api/v1/admin/ai-prompts",
            new { name, systemPrompt = "You are a helpful wellness assistant.", model = "claude-opus-4-8", isActive = false });
        Assert.Equal(HttpStatusCode.OK, create.StatusCode);
        var id = JsonDocument.Parse(await create.Content.ReadAsStringAsync())
            .RootElement.GetProperty("data").GetProperty("id").GetString();

        var activate = await creator.PutAsJsonAsync($"/api/v1/admin/ai-prompts/{id}/activate", new { });
        Assert.Equal(HttpStatusCode.OK, activate.StatusCode);
    }

    [Fact]
    public async Task AiPrompts_Activate_WithoutPermission_Returns403()
    {
        var res = await Client("ai_prompts.view")
            .PutAsJsonAsync($"/api/v1/admin/ai-prompts/{Guid.NewGuid()}/activate", new { });
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    // ── Notifications broadcast ───────────────────────────────────────────────
    [Fact]
    public async Task Notifications_Broadcast_WithPermission_Returns200()
    {
        var res = await Client("notifications.broadcast").PostAsJsonAsync(
            "/api/v1/admin/notifications/broadcast",
            new { title = "Health tip", body = "Stay hydrated!", deepLink = (string?)null });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Notifications_Broadcast_WithoutPermission_Returns403()
    {
        var res = await Client("notifications.view").PostAsJsonAsync(
            "/api/v1/admin/notifications/broadcast", new { title = "x", body = "y", deepLink = (string?)null });
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    // ── Support queue ─────────────────────────────────────────────────────────
    [Fact]
    public async Task Support_List_WithPermission_Returns200()
    {
        var res = await Client("support.view").GetAsync("/api/v1/admin/support/tickets");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Support_Reply_WithoutPermission_Returns403()
    {
        var res = await Client("support.view")
            .PostAsJsonAsync($"/api/v1/admin/support/tickets/{Guid.NewGuid()}/reply", new { body = "hi" });
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    // ── Analytics summary ─────────────────────────────────────────────────────
    [Fact]
    public async Task Analytics_Summary_WithPermission_Returns200()
    {
        var res = await Client("analytics.view").GetAsync("/api/v1/admin/analytics/summary");
        Assert.True(res.IsSuccessStatusCode, await res.Content.ReadAsStringAsync());
        Assert.Contains("bookingsByStatus", await res.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Analytics_Summary_WithoutPermission_Returns403()
    {
        var res = await Client("users.view").GetAsync("/api/v1/admin/analytics/summary");
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }
}
