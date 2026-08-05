using System.Net;
using System.Net.Http.Headers;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// Admin module-grid endpoints: permission-gated, correct routing + envelope.
public class AdminGridsIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public AdminGridsIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    private HttpClient AdminClient(params string[] permissions)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "admin");
        using var scope = _factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var (token, _) = jwt.IssueAccessToken(Guid.NewGuid(), "super_admin", permissions, "admin-portal");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task AdminBookings_WithPermission_Returns200()
    {
        var res = await AdminClient("bookings.view").GetAsync("/api/v1/admin/bookings?page=1&pageSize=20");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        Assert.Contains("\"pagination\"", await res.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task AdminBookings_WithoutPermission_Returns403()
    {
        var res = await AdminClient("users.view").GetAsync("/api/v1/admin/bookings");
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    [Fact]
    public async Task AdminHomeSections_WithPermission_Returns200()
    {
        var res = await AdminClient("home_layout.view").GetAsync("/api/v1/admin/home/sections");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task AdminUsers_WithPermission_Returns200()
    {
        var res = await AdminClient("users.view").GetAsync("/api/v1/admin/users?page=1&pageSize=20");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }
}
