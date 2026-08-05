using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Partner self-service, own data only (Section 7).
public class PartnerService : IPartnerService
{
    private readonly IAppDbContext _db;
    public PartnerService(IAppDbContext db) => _db = db;

    public async Task<object> GetDashboardAsync(Guid partnerId, CancellationToken ct = default)
    {
        var bookings = await _db.Set<Booking>().CountAsync(b => b.PartnerId == partnerId, ct);
        var commission = await _db.Set<PartnerCommission>().Where(c => c.PartnerId == partnerId)
            .SumAsync(c => (decimal?)c.CommissionAmount, ct) ?? 0m;
        return new { bookings, totalCommission = commission };
    }

    public async Task<IReadOnlyList<PartnerCommission>> GetCommissionsAsync(Guid partnerId, CancellationToken ct = default)
        => await _db.Set<PartnerCommission>().AsNoTracking().Where(c => c.PartnerId == partnerId)
            .OrderByDescending(c => c.CreatedAt).ToListAsync(ct);
}
