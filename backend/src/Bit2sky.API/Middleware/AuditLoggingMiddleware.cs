using System.Security.Claims;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;

namespace Bit2sky.API.Middleware;

// Persists sensitive actions to core.audit_logs (Section 4H). Mutating admin actions
// and report downloads are recorded after a successful response.
public class AuditLoggingMiddleware
{
    private readonly RequestDelegate _next;

    public AuditLoggingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        await _next(context);

        if (!ShouldAudit(context)) return;

        var db = context.RequestServices.GetService(typeof(IAppDbContext)) as IAppDbContext;
        if (db is null) return;

        var sub = context.User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? context.User.FindFirstValue("sub");
        Guid? userId = Guid.TryParse(sub, out var id) ? id : null;

        var entry = new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            UserRole = context.User.FindFirstValue("role"),
            Action = MapAction(context.Request.Method, context.Request.Path),
            EntityType = DeriveEntityType(context.Request.Path),
            EntityId = null,
            IpAddress = context.Connection.RemoteIpAddress?.ToString(),
            UserAgent = context.Request.Headers.UserAgent.ToString(),
            CorrelationId = context.Items[CorrelationIdMiddleware.HeaderName]?.ToString(),
        };

        db.Set<AuditLog>().Add(entry);
        await db.SaveChangesAsync(context.RequestAborted);
    }

    private static bool ShouldAudit(HttpContext context)
    {
        if (context.Response.StatusCode is < 200 or >= 300) return false;
        var path = context.Request.Path.Value ?? string.Empty;
        var method = context.Request.Method;
        var isMutation = method is "POST" or "PUT" or "DELETE" or "PATCH";
        var isAdmin = path.StartsWith("/api/v1/admin", StringComparison.OrdinalIgnoreCase)
                      || path.StartsWith("/admin", StringComparison.OrdinalIgnoreCase);
        var isReportDownload = path.Contains("/reports/", StringComparison.OrdinalIgnoreCase)
                               && path.Contains("download", StringComparison.OrdinalIgnoreCase);
        return (isAdmin && isMutation) || isReportDownload;
    }

    private static AuditAction MapAction(string method, string path) => method switch
    {
        "POST" when path.Contains("export") => AuditAction.Export,
        "POST" => AuditAction.Create,
        "PUT" or "PATCH" => AuditAction.Update,
        "DELETE" => AuditAction.Delete,
        _ when path.Contains("download") => AuditAction.Download,
        _ => AuditAction.View,
    };

    private static string DeriveEntityType(string path)
    {
        var segments = path.Split('/', StringSplitOptions.RemoveEmptyEntries);
        var idx = Array.FindIndex(segments, s => s.Equals("admin", StringComparison.OrdinalIgnoreCase));
        if (idx >= 0 && idx + 1 < segments.Length) return segments[idx + 1];
        return segments.Length > 0 ? segments[^1] : "unknown";
    }
}
