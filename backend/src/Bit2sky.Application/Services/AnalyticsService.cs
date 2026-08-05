using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Aggregate business metrics for the admin Reports dashboard (Section 11).
public class AnalyticsService : IAnalyticsService
{
    private readonly IAppDbContext _db;

    public AnalyticsService(IAppDbContext db) => _db = db;

    // HashSet (not array) so `.Contains` binds to the instance method — an array
    // would resolve to ReadOnlySpan<T>.Contains, which the LINQ evaluator can't compile.
    private static readonly HashSet<BookingStatus> Unrealized =
        new() { BookingStatus.Pending, BookingStatus.Cancelled, BookingStatus.NoShow };

    private static readonly HashSet<RefundStatus> PendingRefundStates =
        new() { RefundStatus.Requested, RefundStatus.Approved, RefundStatus.Processing };

    public async Task<AnalyticsSummary> GetSummaryAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var startOfDay = new DateTimeOffset(now.Year, now.Month, now.Day, 0, 0, 0, TimeSpan.Zero);
        var startOfMonth = new DateTimeOffset(now.Year, now.Month, 1, 0, 0, 0, TimeSpan.Zero);

        var totalUsers = await _db.Set<User>()
            .CountAsync(u => u.IsActive && !u.IsDeleted && !u.IsAdminPortalUser, ct);

        var bookings = _db.Set<Booking>().AsNoTracking();
        var totalBookings = await bookings.CountAsync(ct);
        var bookingsToday = await bookings.CountAsync(b => b.CreatedAt >= startOfDay, ct);

        var realized = bookings.Where(b => !Unrealized.Contains(b.Status));
        var revenueTotal = await realized.SumAsync(b => (decimal?)b.AmountPayable, ct) ?? 0m;
        var revenueThisMonth = await realized.Where(b => b.CreatedAt >= startOfMonth)
            .SumAsync(b => (decimal?)b.AmountPayable, ct) ?? 0m;

        // Group client-side — robust across EF providers (InMemory GroupBy is flaky).
        var statuses = await bookings.Select(b => b.Status).ToListAsync(ct);
        var byStatus = statuses
            .GroupBy(s => s)
            .Select(g => new StatusCount(g.Key.ToString(), g.Count()))
            .OrderByDescending(x => x.Count)
            .ToList();

        var openTickets = await _db.Set<SupportTicket>()
            .CountAsync(t => t.Status != TicketStatus.Closed && t.Status != TicketStatus.Resolved, ct);
        var pendingRefunds = await _db.Set<Refund>()
            .CountAsync(r => PendingRefundStates.Contains(r.Status), ct);
        var activeCoupons = await _db.Set<Coupon>().CountAsync(c => c.IsActive, ct);

        return new AnalyticsSummary(
            totalUsers, totalBookings, bookingsToday,
            revenueTotal, revenueThisMonth,
            openTickets, pendingRefunds, activeCoupons, byStatus);
    }
}
