using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Closes group bookings past their expiry (Section 16).
public class GroupBookingExpiryJob
{
    private readonly IAppDbContext _db;
    public GroupBookingExpiryJob(IAppDbContext db) => _db = db;

    public async Task ExecuteAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var expired = await _db.Set<GroupBooking>()
            .Where(g => g.Status == GroupBookingStatus.Open && g.ExpiresAt < now).ToListAsync(ct);
        foreach (var g in expired) g.Status = GroupBookingStatus.Expired;
        await _db.SaveChangesAsync(ct);
    }
}
