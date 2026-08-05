using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Recurring test subscriptions, own only (Section 7).
public class SubscriptionService : ISubscriptionService
{
    private readonly IAppDbContext _db;
    public SubscriptionService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<Subscription>> ListAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<Subscription>().AsNoTracking().Where(s => s.UserId == userId)
            .OrderByDescending(s => s.CreatedAt).ToListAsync(ct);

    public async Task<Subscription> CreateAsync(Guid userId, SubscriptionRequest req, CancellationToken ct = default)
    {
        var sub = new Subscription
        {
            Id = Guid.NewGuid(), UserId = userId, PackageId = req.PackageId, TestId = req.TestId,
            Frequency = req.Frequency, Status = SubscriptionStatus.Active, StartDate = req.StartDate,
            NextBookingDate = req.StartDate, PricePerCycle = req.PricePerCycle,
        };
        _db.Set<Subscription>().Add(sub);
        await _db.SaveChangesAsync(ct);
        return sub;
    }

    public async Task PauseAsync(Guid userId, Guid id, DateOnly? until, CancellationToken ct = default)
    {
        var sub = await OwnedAsync(userId, id, ct);
        sub.Status = SubscriptionStatus.Paused;
        sub.PausedUntil = until;
        await _db.SaveChangesAsync(ct);
    }

    public async Task ResumeAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var sub = await OwnedAsync(userId, id, ct);
        sub.Status = SubscriptionStatus.Active;
        sub.PausedUntil = null;
        await _db.SaveChangesAsync(ct);
    }

    public async Task CancelAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var sub = await OwnedAsync(userId, id, ct);
        sub.Status = SubscriptionStatus.Cancelled;
        await _db.SaveChangesAsync(ct);
    }

    private async Task<Subscription> OwnedAsync(Guid userId, Guid id, CancellationToken ct)
        => await _db.Set<Subscription>().FirstOrDefaultAsync(s => s.Id == id && s.UserId == userId, ct)
           ?? throw new NotFoundAppException();
}
