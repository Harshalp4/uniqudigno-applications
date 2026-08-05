namespace Bit2sky.Application.Abstractions;

public record StatusCount(string Status, int Count);

// Business summary for the admin Reports dashboard (Section 11). Aggregates only —
// no PHI. Revenue counts realized bookings (excludes Pending/Cancelled/NoShow).
public record AnalyticsSummary(
    int TotalUsers,
    int TotalBookings,
    int BookingsToday,
    decimal RevenueTotal,
    decimal RevenueThisMonth,
    int OpenTickets,
    int PendingRefunds,
    int ActiveCoupons,
    IReadOnlyList<StatusCount> BookingsByStatus);

public interface IAnalyticsService
{
    Task<AnalyticsSummary> GetSummaryAsync(CancellationToken ct = default);
}
