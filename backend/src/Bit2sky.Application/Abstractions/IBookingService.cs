using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;

namespace Bit2sky.Application.Abstractions;

// PaymentMethod: "online" (default) creates a Razorpay order for the checkout
// sheet; "cod" records CashOnCollection and skips the gateway entirely.
public record CreateBookingRequest(Guid? AddressId, Guid? SlotId, Guid? FamilyMemberId, DateOnly ScheduledDate, TimeOnly? ScheduledTime, string? PaymentMethod = null);
// RazorpayKeyId is the PUBLIC key id the mobile checkout sheet needs; null when
// the gateway isn't configured (dev) or the booking is COD / fully wallet-paid.
public record CreateBookingResult(Guid BookingId, string BookingNumber, string? RazorpayOrderId, decimal AmountPayable, string? RazorpayKeyId = null);
public record ConfirmBookingRequest(string RazorpayPaymentId, string RazorpaySignature);
// Reschedule to a new date (and optionally a new slot). Honors the
// booking_reschedule_max / booking_reschedule_window_hours config keys.
public record RescheduleBookingRequest(DateOnly ScheduledDate, TimeOnly? ScheduledTime, Guid? SlotId);

// Admin grid row — no PHI beyond a masked customer label.
public record AdminBookingDto(
    Guid Id, string BookingNumber, string Customer, string Status,
    DateOnly ScheduledDate, string? ScheduledTime, decimal AmountPayable,
    bool TechnicianAssigned, DateTimeOffset CreatedAt);

public record BookingItemDto(string ItemName, decimal Mrp, decimal Price);

// Customer-facing booking detail: payment state rides along (COD "Paid" flips the
// tracker), and the raw entity (with RazorpaySignature etc.) never hits the wire.
public record BookingDetailDto(
    Guid Id, string BookingNumber, string Status,
    DateOnly ScheduledDate, string? ScheduledTime, Guid? SlotId,
    string? PatientName, decimal ItemsTotal, decimal DiscountTotal,
    decimal WalletApplied, decimal AmountPayable,
    int RescheduleCount, int MaxReschedules,
    string PaymentStatus, string PaymentMethod, DateTimeOffset? PaidAt,
    IReadOnlyList<BookingItemDto> Items);

public interface IBookingService
{
    Task<CreateBookingResult> CreateAsync(Guid userId, CreateBookingRequest req, CancellationToken ct = default);
    Task ConfirmAsync(Guid userId, Guid bookingId, ConfirmBookingRequest req, CancellationToken ct = default);
    Task<BookingDetailDto> GetAsync(Guid userId, string role, Guid? partnerId, Guid bookingId, CancellationToken ct = default);
    Task<IReadOnlyList<Booking>> ListAsync(Guid userId, string role, Guid? partnerId, CancellationToken ct = default);
    Task CancelAsync(Guid userId, Guid bookingId, string? reason, CancellationToken ct = default);
    Task<BookingDetailDto> RescheduleAsync(Guid userId, Guid bookingId, RescheduleBookingRequest req, CancellationToken ct = default);
    Task<PagedResult<AdminBookingDto>> AdminListAsync(BookingStatus? status, PageRequest page, CancellationToken ct = default);
    Task AssignTechnicianAsync(Guid bookingId, Guid technicianId, CancellationToken ct = default);
}
