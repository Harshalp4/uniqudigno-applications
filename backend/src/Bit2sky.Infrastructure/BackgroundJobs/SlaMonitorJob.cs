using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Escalates support tickets past their SLA (Section 16).
public class SlaMonitorJob
{
    private readonly IAppDbContext _db;
    public SlaMonitorJob(IAppDbContext db) => _db = db;

    public async Task ExecuteAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var breached = await _db.Set<SupportTicket>()
            .Where(t => t.Status != TicketStatus.Closed && t.SlaDueAt != null && t.SlaDueAt < now
                        && t.Priority != TicketPriority.Urgent)
            .ToListAsync(ct);
        foreach (var t in breached) t.Priority = TicketPriority.Urgent;
        await _db.SaveChangesAsync(ct);
    }
}
