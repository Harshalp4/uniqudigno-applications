using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Infrastructure.Data;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// Exercises the admin (password → mandatory TOTP enroll/verify) and technician
// (employee-id + password) login flows end-to-end against the seeded demo accounts.
public class AuthFlowIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public AuthFlowIntegrationTests(TestWebAppFactory factory)
    {
        _factory = factory;
        Seed();
    }

    private void Seed()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var hasher = scope.ServiceProvider.GetRequiredService<IHashService>();
        DataSeeder.SeedAsync(db, hasher).GetAwaiter().GetResult();
    }

    private HttpClient AdminClient()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "admin");
        return client;
    }

    private static async Task<JsonElement> DataOf(HttpResponseMessage res)
    {
        var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
        return doc.RootElement.GetProperty("data").Clone();
    }

    [Fact]
    public async Task AdminLogin_FirstTime_EnrollsAndVerifies2fa()
    {
        var client = AdminClient();

        // Step 1: password → enrollment required (mandatory TOTP, no tokens yet).
        var login = await client.PostAsJsonAsync("/api/v1/auth/admin/login",
            new { email = DataSeeder.DefaultAdminEmail, password = DataSeeder.DefaultAdminPassword });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var loginData = await DataOf(login);
        Assert.True(loginData.GetProperty("enrollRequired").GetBoolean());
        Assert.False(loginData.GetProperty("twoFactorRequired").GetBoolean());
        var sessionId = loginData.GetProperty("sessionId").GetString()!;

        // Step 2: enroll → secret + 8 single-use backup codes.
        var enroll = await client.PostAsJsonAsync("/api/v1/auth/admin/2fa/enroll", new { sessionId });
        Assert.Equal(HttpStatusCode.OK, enroll.StatusCode);
        var enrollData = await DataOf(enroll);
        Assert.False(string.IsNullOrWhiteSpace(enrollData.GetProperty("secret").GetString()));
        var backupCodes = enrollData.GetProperty("backupCodes").EnumerateArray()
            .Select(e => e.GetString()!).ToList();
        Assert.Equal(8, backupCodes.Count);

        // Step 3: verify with a backup code → access token + role.
        var verify = await client.PostAsJsonAsync("/api/v1/auth/admin/2fa/verify",
            new { sessionId, code = backupCodes[0] });
        Assert.Equal(HttpStatusCode.OK, verify.StatusCode);
        var verifyData = await DataOf(verify);
        Assert.False(string.IsNullOrWhiteSpace(verifyData.GetProperty("accessToken").GetString()));
        Assert.Equal("super_admin", verifyData.GetProperty("role").GetString());
    }

    [Fact]
    public async Task AdminLogin_WrongPassword_Returns401()
    {
        var res = await AdminClient().PostAsJsonAsync("/api/v1/auth/admin/login",
            new { email = DataSeeder.DefaultAdminEmail, password = "wrong-password" });
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task AdminLogin_UnknownEmail_Returns401_NoEnumeration()
    {
        var res = await AdminClient().PostAsJsonAsync("/api/v1/auth/admin/login",
            new { email = "nobody@nowhere.com", password = "whatever-12345" });
        // Same shape as a wrong password — never reveals the account doesn't exist.
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task TechnicianLogin_ValidCredentials_ReturnsToken()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "technician");

        var res = await client.PostAsJsonAsync("/api/v1/auth/technician/login",
            new { employeeId = DataSeeder.DefaultTechEmployeeId, password = DataSeeder.DefaultTechPassword });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        var data = await DataOf(res);
        Assert.False(string.IsNullOrWhiteSpace(data.GetProperty("accessToken").GetString()));
        Assert.Equal("technician", data.GetProperty("role").GetString());
    }

    [Fact]
    public async Task TechnicianLogin_WrongPassword_Returns401()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "technician");

        var res = await client.PostAsJsonAsync("/api/v1/auth/technician/login",
            new { employeeId = DataSeeder.DefaultTechEmployeeId, password = "nope" });
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }
}
