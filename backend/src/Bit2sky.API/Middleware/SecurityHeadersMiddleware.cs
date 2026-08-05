namespace Bit2sky.API.Middleware;

// Full OWASP security headers + CSP from Section 4B.
public class SecurityHeadersMiddleware
{
    private const string Csp =
        "default-src 'self'; " +
        "img-src 'self' https://images.unsplash.com https://*.blob.core.windows.net data:; " +
        "font-src 'self' https://fonts.gstatic.com; " +
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
        "script-src 'self'; " +
        "connect-src 'self' https://api.anthropic.com; " +
        "frame-ancestors 'none';";

    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next) => _next = next;

    public Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var h = context.Response.Headers;
            h["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload";
            h["X-Content-Type-Options"] = "nosniff";
            h["X-Frame-Options"] = "DENY";
            h["X-XSS-Protection"] = "1; mode=block";
            h["Referrer-Policy"] = "strict-origin-when-cross-origin";
            h["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
            h["Content-Security-Policy"] = Csp;
            return Task.CompletedTask;
        });
        return _next(context);
    }
}
