namespace Bit2sky.API.Configuration;

/// <summary>
/// Converts URL-style connection strings into the keyword formats Npgsql and
/// StackExchange.Redis actually understand.
///
/// Render (like Heroku and Fly) exposes managed datastores as URLs —
/// <c>postgresql://user:pass@host:5432/db</c> and <c>rediss://:pass@host:6379</c>.
/// Neither driver parses those, so wiring a Render connection string straight
/// into configuration fails at startup with an unhelpful format error. Anything
/// that isn't such a URL is returned untouched, so local keyword-style strings
/// and Azure-hosted values keep working unchanged.
/// </summary>
public static class ConnectionStringNormalizer
{
    /// <summary>Rewrites the Postgres and Redis connection strings in-place, if URL-shaped.</summary>
    public static void NormalizeInto(ConfigurationManager config)
    {
        foreach (var key in new[] { "ConnectionStrings:Postgres", "ConnectionStrings:Redis" })
        {
            var value = config[key];
            if (string.IsNullOrWhiteSpace(value)) continue;
            config[key] = Normalize(value);
        }
    }

    /// <summary>
    /// Returns a driver-native connection string. Input that isn't a
    /// postgres/redis URL is passed through unchanged.
    /// </summary>
    public static string Normalize(string value)
    {
        if (!Uri.TryCreate(value, UriKind.Absolute, out var uri)) return value;

        return uri.Scheme.ToLowerInvariant() switch
        {
            "postgres" or "postgresql" => Postgres(uri),
            "redis" or "rediss" => Redis(uri),
            _ => value,
        };
    }

    static (string User, string Password) Credentials(Uri uri)
    {
        // UserInfo is empty when the datastore takes no auth (Render's internal
        // key-value endpoint), and ":password" when there is no username.
        var parts = uri.UserInfo.Split(':', 2);
        return (Uri.UnescapeDataString(parts[0]),
                parts.Length > 1 ? Uri.UnescapeDataString(parts[1]) : string.Empty);
    }

    static string Postgres(Uri uri)
    {
        var (user, password) = Credentials(uri);
        var database = uri.AbsolutePath.Trim('/');
        var port = uri.Port > 0 ? uri.Port : 5432;

        // Honour an explicit ?sslmode=, otherwise require TLS. Render terminates
        // Postgres TLS with a certificate that doesn't chain to a public root, so
        // the certificate is trusted explicitly — without that, Require fails.
        var sslMode = System.Web.HttpUtility.ParseQueryString(uri.Query)["sslmode"] ?? "Require";

        return $"Host={uri.Host};Port={port};Database={database};" +
               $"Username={user};Password={password};" +
               $"SSL Mode={sslMode};Trust Server Certificate=true";
    }

    static string Redis(Uri uri)
    {
        var (_, password) = Credentials(uri);
        var port = uri.Port > 0 ? uri.Port : 6379;
        // rediss:// means TLS; Render's internal redis:// endpoint is plaintext
        // on the private network.
        var ssl = uri.Scheme.Equals("rediss", StringComparison.OrdinalIgnoreCase);

        var config = $"{uri.Host}:{port},ssl={ssl}";
        if (!string.IsNullOrEmpty(password)) config += $",password={password}";
        return config;
    }
}
