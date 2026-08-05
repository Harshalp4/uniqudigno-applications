using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Infrastructure.Data;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

public class SecurityIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public SecurityIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    private HttpClient Client()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "flutter_ios");
        return client;
    }

    [Fact]
    public async Task Health_Returns200()
    {
        var res = await _factory.CreateClient().GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Jwks_ExposesPublicKey()
    {
        var res = await _factory.CreateClient().GetAsync("/.well-known/jwks.json");
        res.EnsureSuccessStatusCode();
        var body = await res.Content.ReadAsStringAsync();
        Assert.Contains("\"keys\"", body);
        Assert.Contains("RS256", body);
    }

    [Fact]
    public async Task MissingAppSource_Returns400()
    {
        // No X-App-Source header.
        var res = await _factory.CreateClient().GetAsync("/api/v1/tests");
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithoutAuth_Returns401()
    {
        var res = await Client().GetAsync("/api/v1/users/me");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task SecurityHeaders_ArePresent()
    {
        var res = await Client().GetAsync("/health");
        Assert.True(res.Headers.Contains("X-Content-Type-Options"));
        Assert.True(res.Headers.Contains("Content-Security-Policy"));
        Assert.True(res.Headers.Contains("X-Frame-Options"));
    }

    [Fact]
    public async Task InvalidMobile_Returns400()
    {
        var res = await Client().PostAsJsonAsync("/api/v1/auth/otp/send", new { mobile = "not-a-number" });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Idor_OtherUsersReport_Returns404()
    {
        var ownerId = Guid.NewGuid();
        var attackerId = Guid.NewGuid();
        Guid reportId;

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Users.Add(new User { Id = ownerId, Mobile = "+919000000001" });
            db.Users.Add(new User { Id = attackerId, Mobile = "+919000000002" });
            var report = new LabReport { Id = Guid.NewGuid(), UserId = ownerId, Title = "Owner report", Status = ReportStatus.Ready };
            db.LabReports.Add(report);
            await db.SaveChangesAsync();
            reportId = report.Id;
        }

        var token = IssueToken(attackerId);
        var client = Client();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var res = await client.GetAsync($"/api/v1/reports/{reportId}");
        // Ownership fails → 404 parity (no enumeration), never 403-with-detail.
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    private string IssueToken(Guid userId)
    {
        using var scope = _factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var (token, _) = jwt.IssueAccessToken(userId, "customer", Array.Empty<string>(), "test-device");
        return token;
    }
}
