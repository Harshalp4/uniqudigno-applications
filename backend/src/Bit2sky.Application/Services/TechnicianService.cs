using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Technician field operations (Section 9). A technician sees and mutates ONLY the
// bookings assigned to them — resolved from the logged-in user, never trusted from
// the client. Status transitions are validated server-side (state machine, C14).
public class TechnicianService : ITechnicianService
{
    private readonly IAppDbContext _db;
    private readonly IBookingEventsPublisher _events;

    public TechnicianService(IAppDbContext db, IBookingEventsPublisher events)
    {
        _db = db;
        _events = events;
    }

    // Transitions a technician is allowed to drive, in order.
    private static readonly Dictionary<BookingStatus, BookingStatus> Next = new()
    {
        [BookingStatus.Confirmed] = BookingStatus.TechnicianAssigned,
        [BookingStatus.TechnicianAssigned] = BookingStatus.SampleCollected,
        [BookingStatus.SampleCollected] = BookingStatus.InLab,
    };

    private async Task<Technician> ResolveTechnicianAsync(Guid userId, CancellationToken ct)
        => await _db.Set<Technician>().FirstOrDefaultAsync(t => t.UserId == userId && t.IsActive, ct)
           ?? throw new ForbiddenAppException("Not a technician account.");

    public async Task<IReadOnlyList<TechBookingDto>> TodaysBookingsAsync(Guid userId, CancellationToken ct = default)
    {
        var tech = await ResolveTechnicianAsync(userId, ct);
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);

        var rows = await _db.Set<Booking>().AsNoTracking()
            .Where(b => b.TechnicianId == tech.Id
                && b.ScheduledDate <= today
                && b.Status != BookingStatus.Completed
                && b.Status != BookingStatus.Cancelled
                && b.Status != BookingStatus.NoShow)
            .OrderBy(b => b.ScheduledTime)
            .Select(b => new
            {
                b.Id, b.BookingNumber, b.Status, b.ScheduledDate, b.ScheduledTime,
                b.CollectionType, ItemCount = b.Items.Count
            })
            .ToListAsync(ct);

        return rows.Select(b => new TechBookingDto(
            b.Id, b.BookingNumber, b.Status.ToString(), b.ScheduledDate,
            b.ScheduledTime?.ToString("HH:mm"), b.CollectionType.ToString(), b.ItemCount)).ToList();
    }

    public async Task<string> AdvanceStatusAsync(Guid userId, Guid bookingId, AdvanceStatusRequest req, CancellationToken ct = default)
    {
        var tech = await ResolveTechnicianAsync(userId, ct);

        // Own assigned only — 404 (not 403) so unassigned bookings aren't enumerable.
        var booking = await _db.Set<Booking>()
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.TechnicianId == tech.Id, ct)
            ?? throw new NotFoundAppException();

        if (!Enum.TryParse<BookingStatus>(req.Status, ignoreCase: true, out var target))
            throw new ValidationAppException(new[] { new ApiError { Field = "status", Message = "Unknown status." } });

        // The target must be the single legal next step from the current status.
        if (!Next.TryGetValue(booking.Status, out var allowed) || allowed != target)
            throw new ConflictAppException($"Cannot move a {booking.Status} booking to {target}.");

        if (target == BookingStatus.SampleCollected)
        {
            if (string.IsNullOrWhiteSpace(req.SampleBarcode))
                throw new ValidationAppException(new[] { new ApiError { Field = "sampleBarcode", Message = "Scan the sample barcode to confirm collection." } });
            booking.SampleBarcode = req.SampleBarcode.Trim();
            if (!string.IsNullOrWhiteSpace(req.PhotoUrl))
                booking.CollectionPhotoUrl = req.PhotoUrl.Trim();

            // COD: cash changes hands at collection — the same transaction that marks
            // the sample collected marks the payment Paid, so the two can't diverge.
            var payment = await _db.Set<Payment>().FirstOrDefaultAsync(p => p.BookingId == booking.Id, ct);
            if (payment is { Method: PaymentMethod.CashOnCollection, Status: not PaymentStatus.Paid })
            {
                if (req.CodCollected != true)
                    throw new ValidationAppException(new[] { new ApiError { Field = "codCollected", Message = "Confirm cash was collected for this pay-on-collection booking." } });
                payment.Status = PaymentStatus.Paid;
                payment.PaidAt = DateTimeOffset.UtcNow;
            }
        }

        booking.Status = target;
        booking.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);

        var payStatus = (await _db.Set<Payment>().AsNoTracking()
            .Where(p => p.BookingId == booking.Id).Select(p => (PaymentStatus?)p.Status).FirstOrDefaultAsync(ct)
            ?? PaymentStatus.Created).ToString();
        await _events.PublishAsync(new BookingStatusChangedEvent(
            booking.Id, booking.BookingNumber, booking.Status.ToString(),
            payStatus, booking.RescheduleCount, booking.UpdatedAt), ct);
        return target.ToString();
    }
}
