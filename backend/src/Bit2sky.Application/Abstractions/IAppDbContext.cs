using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Abstractions;

// Persistence abstraction so Application services depend on the DbContext contract,
// not the Infrastructure implementation.
public interface IAppDbContext
{
    DbSet<TEntity> Set<TEntity>() where TEntity : class;
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    /// Atomically take one seat on a slot; false when the slot is full,
    /// unavailable, or missing. Safe under concurrency (no oversell).
    Task<bool> TryReserveSlotSeatAsync(Guid slotId, CancellationToken ct = default);

    /// Give one seat back (floor at zero). No-op for a missing slot.
    Task ReleaseSlotSeatAsync(Guid slotId, CancellationToken ct = default);
}
