using Bit2sky.API.Configuration;
using Xunit;

namespace Bit2sky.UnitTests;

// Runs on every startup and converts what Render hands the app. A bug here
// surfaces as an opaque driver format error during deploy, so the URL shapes
// Render actually emits are pinned down explicitly.
public class ConnectionStringNormalizerTests
{
    [Fact]
    public void Postgres_Url_Becomes_Npgsql_Keywords()
    {
        var result = ConnectionStringNormalizer.Normalize(
            "postgresql://bit2sky:s3cret@dpg-abc123-a.singapore-postgres.render.com:5432/bit2sky");

        Assert.Contains("Host=dpg-abc123-a.singapore-postgres.render.com", result);
        Assert.Contains("Port=5432", result);
        Assert.Contains("Database=bit2sky", result);
        Assert.Contains("Username=bit2sky", result);
        Assert.Contains("Password=s3cret", result);
        Assert.Contains("SSL Mode=Require", result);
        Assert.Contains("Trust Server Certificate=true", result);
    }

    [Fact]
    public void Postgres_Url_Without_Port_Defaults_To_5432()
        => Assert.Contains("Port=5432",
            ConnectionStringNormalizer.Normalize("postgres://u:p@db.internal/mydb"));

    [Fact]
    public void Postgres_Url_Honours_Explicit_SslMode()
        => Assert.Contains("SSL Mode=Disable",
            ConnectionStringNormalizer.Normalize("postgres://u:p@localhost:5432/db?sslmode=Disable"));

    [Fact]
    public void Postgres_Password_Is_Url_Decoded()
    {
        // Render generates passwords containing characters that must be escaped
        // in a URL; leaving them escaped produces a wrong password and a login
        // failure that looks like a credentials problem.
        var result = ConnectionStringNormalizer.Normalize(
            "postgres://u:p%40ss%3Aword@host:5432/db");
        Assert.Contains("Password=p@ss:word", result);
    }

    [Fact]
    public void Redis_Url_Becomes_StackExchange_Config()
    {
        var result = ConnectionStringNormalizer.Normalize("redis://red-abc123:6379");
        Assert.Contains("red-abc123:6379", result);
        Assert.Contains("ssl=False", result);
    }

    [Fact]
    public void Rediss_Url_Enables_Tls_And_Password()
    {
        var result = ConnectionStringNormalizer.Normalize("rediss://:p4ss@red-abc.render.com:6380");
        Assert.Contains("red-abc.render.com:6380", result);
        Assert.Contains("ssl=True", result);
        Assert.Contains("password=p4ss", result);
    }

    [Fact]
    public void Redis_Without_Credentials_Omits_Password()
        => Assert.DoesNotContain("password=",
            ConnectionStringNormalizer.Normalize("redis://red-abc123:6379"));

    [Theory]
    // Already driver-native — must survive untouched, or local and Azure
    // deployments break.
    [InlineData("Host=localhost;Database=bit2sky;Username=postgres;Password=postgres")]
    [InlineData("localhost:6379")]
    [InlineData("")]
    public void Non_Url_Values_Pass_Through_Unchanged(string value)
        => Assert.Equal(value, ConnectionStringNormalizer.Normalize(value));

    [Fact]
    public void Unrelated_Url_Schemes_Pass_Through_Unchanged()
    {
        const string azure = "https://myaccount.blob.core.windows.net/";
        Assert.Equal(azure, ConnectionStringNormalizer.Normalize(azure));
    }
}
