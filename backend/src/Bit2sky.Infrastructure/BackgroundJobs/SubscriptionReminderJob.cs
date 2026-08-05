using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Reminds users of upcoming subscription cycles (Section 16).
public class SubscriptionReminderJob
{
    private readonly IAppDbContext _db;
    private readonly INotificationOrchestrator _notify;
    public SubscriptionReminderJob(IAppDbContext db, INotificationOrchestrator notify) { _db = db; _notify = notify; }

    public async Task ExecuteAsync(CancellationToken ct = default)
    {
        var soon = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(3));
        var due = await _db.Set<Subscription>().AsNoTracking()
            .Where(s => s.Status == SubscriptionStatus.Active && s.NextBookingDate == soon)
            .Select(s => s.UserId).ToListAsync(ct);
        foreach (var userId in due)
            await _notify.NotifyAsync(userId, "subscription_reminder",
                new Dictionary<string, string> { ["title"] = "Upcoming test", ["body"] = "Your subscription test is due soon." }, ct);
    }
}
