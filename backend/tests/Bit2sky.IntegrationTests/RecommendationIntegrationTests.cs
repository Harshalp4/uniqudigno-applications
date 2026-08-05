using System.Net;
using Xunit;

namespace Bit2sky.IntegrationTests;

// "Recommended for You" — public endpoint, personalised when authed, popularity
// default (and never a crash) for guests.
public class RecommendationIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public RecommendationIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    [Fact]
    public async Task Recommended_Guest_Returns200()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "flutter_android");
        var res = await client.GetAsync("/api/v1/tests/recommended?take=6");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        Assert.Contains("\"success\":true", await res.Content.ReadAsStringAsync());
    }
}
