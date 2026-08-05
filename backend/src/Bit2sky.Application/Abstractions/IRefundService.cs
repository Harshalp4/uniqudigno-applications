namespace Bit2sky.Application.Abstractions;

// Admin refund-queue row — masked customer, no PHI.
public record RefundDto(
    Guid Id, string BookingNumber, string Customer, decimal Amount,
    string Method, string Status, string? Reason,
    DateTimeOffset CreatedAt, DateTimeOffset? ProcessedAt);

public interface IRefundService
{
    Task<IReadOnlyList<RefundDto>> ListAsync(string? status, CancellationToken ct = default);
    // Approve → mark completed. Gateway reversal is stubbed until Razorpay is wired.
    Task ProcessAsync(Guid id, Guid adminId, CancellationToken ct = default);
    Task RejectAsync(Guid id, Guid adminId, string? reason, CancellationToken ct = default);
}
