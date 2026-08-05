using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public interface IWalletService
{
    Task<Wallet> GetWalletAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<WalletTransaction>> GetTransactionsAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<MembershipTier>> GetTierBenefitsAsync(CancellationToken ct = default);
    Task<Wallet> RedeemAsync(Guid userId, decimal amount, CancellationToken ct = default);
    Task AdminAdjustAsync(Guid targetUserId, decimal amount, string reason, Guid adminId, CancellationToken ct = default);
}

public record SubscriptionRequest(Guid? PackageId, Guid? TestId, Domain.Enums.SubscriptionFrequency Frequency, DateOnly StartDate, decimal PricePerCycle);
public interface ISubscriptionService
{
    Task<IReadOnlyList<Subscription>> ListAsync(Guid userId, CancellationToken ct = default);
    Task<Subscription> CreateAsync(Guid userId, SubscriptionRequest req, CancellationToken ct = default);
    Task PauseAsync(Guid userId, Guid id, DateOnly? until, CancellationToken ct = default);
    Task ResumeAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task CancelAsync(Guid userId, Guid id, CancellationToken ct = default);
}

public record GroupBookingRequest(Guid? PackageId, Guid? TestId, int MinMembers, int MaxMembers, decimal DiscountPercent);
public interface IGroupBookingService
{
    Task<GroupBooking> CreateAsync(Guid userId, GroupBookingRequest req, CancellationToken ct = default);
    Task<GroupBooking> GetByCodeAsync(string code, CancellationToken ct = default);
    Task JoinAsync(Guid userId, string code, CancellationToken ct = default);
    Task<IReadOnlyList<GroupBooking>> MyGroupsAsync(Guid userId, CancellationToken ct = default);
    Task LeaveAsync(Guid userId, Guid id, CancellationToken ct = default);
}

public record CouponValidationResult(bool Valid, decimal Discount, string Message);

// Admin create/edit payload (Section 11). Type is "Percentage" | "Flat".
public record CouponInput(
    string Code, string? Description, string Type, decimal Value,
    decimal? MaxDiscount, decimal? MinOrderValue, int? TotalUsageLimit, int PerUserLimit,
    DateTimeOffset? ValidFrom, DateTimeOffset? ValidUntil, bool IsActive);

public interface ICouponService
{
    Task<CouponValidationResult> ValidateAsync(Guid userId, string code, decimal orderValue, CancellationToken ct = default);
    Task<IReadOnlyList<Coupon>> ListAsync(CancellationToken ct = default);
    Task<Coupon> CreateAsync(CouponInput input, CancellationToken ct = default);
    Task<Coupon> UpdateAsync(Guid id, CouponInput input, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
}

public interface ICashbackService
{
    Task<IReadOnlyList<CashbackOffer>> GetActiveOffersAsync(CancellationToken ct = default);
}
