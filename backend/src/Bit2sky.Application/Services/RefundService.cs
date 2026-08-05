using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Admin refund queue + processing (Section 11 / finance). The actual gateway
// reversal (RazorpayReversal) is stubbed until Razorpay is wired — Process records
// the admin + timestamp and marks the refund completed.
public class RefundService : IRefundService
{
    private readonly IAppDbContext _db;
    private readonly IDataMaskingService _mask;

    public RefundService(IAppDbContext db, IDataMaskingService mask)
    {
        _db = db;
        _mask = mask;
    }

    public async Task<IReadOnlyList<RefundDto>> ListAsync(string? status, CancellationToken ct = default)
    {
        var query = from r in _db.Set<Refund>().AsNoTracking()
                    join b in _db.Set<Booking>().AsNoTracking() on r.BookingId equals b.Id
                    join u in _db.Set<User>().AsNoTracking() on r.UserId equals u.Id
                    select new { r, b.BookingNumber, u.Mobile };

        if (Enum.TryParse<RefundStatus>(status, ignoreCase: true, out var s))
            query = query.Where(x => x.r.Status == s);

        var rows = await query.OrderByDescending(x => x.r.CreatedAt).ToListAsync(ct);
        return rows.Select(x => new RefundDto(
            x.r.Id, x.BookingNumber, _mask.MaskPhone(x.Mobile), x.r.Amount,
            x.r.Method.ToString(), x.r.Status.ToString(), x.r.Reason,
            x.r.CreatedAt, x.r.ProcessedAt)).ToList();
    }

    public async Task ProcessAsync(Guid id, Guid adminId, CancellationToken ct = default)
    {
        var refund = await Pending(id, ct);
        // TODO(razorpay): call gateway reversal here and store RazorpayRefundId.
        refund.Status = RefundStatus.Completed;
        refund.ProcessedByAdminId = adminId;
        refund.ProcessedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
    }

    public async Task RejectAsync(Guid id, Guid adminId, string? reason, CancellationToken ct = default)
    {
        var refund = await Pending(id, ct);
        refund.Status = RefundStatus.Rejected;
        refund.ProcessedByAdminId = adminId;
        refund.ProcessedAt = DateTimeOffset.UtcNow;
        if (!string.IsNullOrWhiteSpace(reason)) refund.Reason = reason;
        await _db.SaveChangesAsync(ct);
    }

    private async Task<Refund> Pending(Guid id, CancellationToken ct)
    {
        var refund = await _db.Set<Refund>().FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new NotFoundAppException();
        if (refund.Status is RefundStatus.Completed or RefundStatus.Rejected)
            throw new ConflictAppException("This refund has already been finalised.");
        return refund;
    }
}
