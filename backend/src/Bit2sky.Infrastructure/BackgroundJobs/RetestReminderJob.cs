using Bit2sky.Application.Abstractions;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Reminds users to re-test based on report cadence (Section 16). Scaffold cadence
// rules pending config; wired and scheduled.
public class RetestReminderJob
{
    private readonly IAppDbContext _db;
    public RetestReminderJob(IAppDbContext db) => _db = db;
    public Task ExecuteAsync(CancellationToken ct = default) => Task.CompletedTask;
}
