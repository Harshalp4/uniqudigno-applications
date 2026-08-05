using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Cashback offer matching (Section 7).
public class CashbackService : ICashbackService
{
    private readonly IAppDbContext _db;
    public CashbackService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<CashbackOffer>> GetActiveOffersAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        return await _db.Set<CashbackOffer>().AsNoTracking()
            .Where(o => o.IsActive
                && (o.ValidFrom == null || o.ValidFrom <= now)
                && (o.ValidUntil == null || o.ValidUntil >= now))
            .ToListAsync(ct);
    }
}
