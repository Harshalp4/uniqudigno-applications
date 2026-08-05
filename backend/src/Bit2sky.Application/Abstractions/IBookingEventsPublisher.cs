namespace Bit2sky.Application.Abstractions;

/// Broadcast payload for the booking-tracking hub (P0d). PaymentStatus rides
/// along so a COD "Paid" flips the customer's tracker live.
public record BookingStatusChangedEvent(
    Guid BookingId, string BookingNumber, string Status,
    string PaymentStatus, int RescheduleCount, DateTimeOffset UpdatedAt);

/// Publishes booking lifecycle changes to connected clients. Implementations
/// must never throw into the calling request — broadcast failure is logged,
/// not surfaced (the state change itself has already committed).
public interface IBookingEventsPublisher
{
    Task PublishAsync(BookingStatusChangedEvent evt, CancellationToken ct = default);
}
