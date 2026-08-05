using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Weekly security-event summary to admins (Section 16 / 4H).
public class SecurityAuditJob
{
    private readonly IAppDbContext _db;
    private readonly ILogger<SecurityAuditJob> _logger;
    public SecurityAuditJob(IAppDbContext db, ILogger<SecurityAuditJob> logger) { _db = db; _logger = logger; }

    public async Task ExecuteAsync(CancellationToken ct = default)
    {
        var since = DateTimeOffset.UtcNow.AddDays(-7);
        var counts = await _db.Set<SecurityEvent>().AsNoTracking()
            .Where(e => e.CreatedAt >= since)
            .GroupBy(e => e.Severity)
            .Select(g => new { Severity = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var critical = counts.FirstOrDefault(c => c.Severity == SecurityEventSeverity.Critical)?.Count ?? 0;
        _logger.LogWarning("Weekly security summary: {Critical} critical events in the last 7 days", critical);
    }
}
