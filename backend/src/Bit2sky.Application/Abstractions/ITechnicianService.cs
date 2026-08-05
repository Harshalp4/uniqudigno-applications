namespace Bit2sky.Application.Abstractions;

// A collection job as seen by the assigned technician (Section 9).
public record TechBookingDto(
    Guid Id, string BookingNumber, string Status, DateOnly ScheduledDate,
    string? ScheduledTime, string CollectionType, int ItemCount);

// Status advance from the field. SampleBarcode is required to mark SampleCollected.
// CodCollected must be true when collecting a cash-on-collection booking — the
// same call flips the payment to Paid (single transaction, no half-state).
public record AdvanceStatusRequest(string Status, string? SampleBarcode, string? PhotoUrl, bool? CodCollected = null);

// Technician field operations — own assigned bookings only (server-enforced).
public interface ITechnicianService
{
    Task<IReadOnlyList<TechBookingDto>> TodaysBookingsAsync(Guid userId, CancellationToken ct = default);
    Task<string> AdvanceStatusAsync(Guid userId, Guid bookingId, AdvanceStatusRequest req, CancellationToken ct = default);
}
