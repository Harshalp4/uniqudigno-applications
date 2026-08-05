namespace Bit2sky.API.Middleware;

// Validates the X-App-Source header against the allowlist (Section 7).
public class AppSourceMiddleware
{
    public const string HeaderName = "X-App-Source";

    private static readonly HashSet<string> Allowed = new(StringComparer.OrdinalIgnoreCase)
    {
        "flutter_ios", "flutter_android", "web", "admin", "technician", "partner",
    };

    private static readonly string[] ExemptPrefixes =
    {
        "/health", "/swagger", "/.well-known", "/hangfire", "/payment/webhook", "/hubs",
    };

    private readonly RequestDelegate _next;

    public AppSourceMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        // CORS preflights never carry custom headers (browser spec) — let the
        // CORS middleware answer them; enforcing here breaks every web client.
        if (HttpMethods.IsOptions(context.Request.Method))
        {
            await _next(context);
            return;
        }

        var path = context.Request.Path.Value ?? string.Empty;
        var exempt = ExemptPrefixes.Any(p => path.StartsWith(p, StringComparison.OrdinalIgnoreCase));

        if (!exempt)
        {
            var source = context.Request.Headers[HeaderName].ToString();
            if (string.IsNullOrWhiteSpace(source) || !Allowed.Contains(source))
            {
                context.Response.StatusCode = StatusCodes.Status400BadRequest;
                await context.Response.WriteAsJsonAsync(new
                {
                    success = false,
                    message = "Invalid or missing X-App-Source header.",
                });
                return;
            }
        }

        await _next(context);
    }
}
