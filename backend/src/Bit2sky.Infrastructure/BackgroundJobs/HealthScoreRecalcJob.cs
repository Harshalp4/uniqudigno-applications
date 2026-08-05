using Bit2sky.Application.Abstractions;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Recomputes health scores (weights from app_config). Scaffold computation pending
// the full scoring spec; wired and scheduled (Section 16 / 19 Phase 2).
public class HealthScoreRecalcJob
{
    private readonly IAppDbContext _db;
    public HealthScoreRecalcJob(IAppDbContext db) => _db = db;

    public Task ExecuteAsync(CancellationToken ct = default) => Task.CompletedTask;
}
