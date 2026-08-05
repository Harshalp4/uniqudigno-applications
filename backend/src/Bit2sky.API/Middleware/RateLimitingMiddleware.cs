namespace Bit2sky.API.Middleware;

// Scaffold placeholder for distributed (Redis) rate limiting.
// Note: the built-in ASP.NET Core rate limiter is also wired in Program.cs.
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;

    public RateLimitingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context) => await _next(context);
}
