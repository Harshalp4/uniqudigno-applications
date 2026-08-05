using Bit2sky.Shared;

namespace Bit2sky.API.Middleware;

// Maps exceptions to the standard envelope with no information leakage (Section 4B).
// 403/404 share the same shape to prevent resource enumeration.
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger, IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (AppException ex)
        {
            await WriteAsync(context, ex.StatusCode, ex.Message, ex.Errors, ex as RateLimitAppException);
        }
        catch (Exception ex)
        {
            var correlationId = context.Items[CorrelationIdMiddleware.HeaderName]?.ToString();
            _logger.LogError(ex, "Unhandled exception for {Path} ({CorrelationId})",
                context.Request.Path, correlationId);
            var message = _env.IsDevelopment()
                ? ex.Message
                : $"An error occurred. Reference: {correlationId}";
            await WriteAsync(context, StatusCodes.Status500InternalServerError, message, null, null);
        }
    }

    private static async Task WriteAsync(HttpContext context, int status, string message,
        IEnumerable<ApiError>? errors, RateLimitAppException? rateLimit)
    {
        if (context.Response.HasStarted) return;
        context.Response.Clear();
        context.Response.StatusCode = status;
        context.Response.ContentType = "application/json";
        if (rateLimit is not null)
            context.Response.Headers.RetryAfter = rateLimit.RetryAfterSeconds.ToString();

        var body = ApiResponse<object>.Fail(message, errors);
        body.CorrelationId = context.Items[CorrelationIdMiddleware.HeaderName]?.ToString();
        await context.Response.WriteAsJsonAsync(body);
    }
}
