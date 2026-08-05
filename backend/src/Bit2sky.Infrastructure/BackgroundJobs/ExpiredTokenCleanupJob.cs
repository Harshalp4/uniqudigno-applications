using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Deletes expired refresh tokens (Section 16).
public class ExpiredTokenCleanupJob
{
    private readonly IAppDbContext _db;
    public ExpiredTokenCleanupJob(IAppDbContext db) => _db = db;

    public async Task ExecuteAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var expired = await _db.Set<RefreshToken>().Where(t => t.ExpiresAt < now).ToListAsync(ct);
        _db.Set<RefreshToken>().RemoveRange(expired);
        var oldOtps = await _db.Set<OtpRequest>().Where(o => o.ExpiresAt < now.AddHours(-24)).ToListAsync(ct);
        _db.Set<OtpRequest>().RemoveRange(oldOtps);
        await _db.SaveChangesAsync(ct);
    }
}
