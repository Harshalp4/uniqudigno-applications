using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// commerce.carts — one active cart per user.
public class Cart
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? CouponId { get; set; }
    public decimal WalletPointsApplied { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<CartItem> Items { get; set; } = new List<CartItem>();
}

// commerce.cart_items.
public class CartItem
{
    public Guid Id { get; set; }
    public Guid CartId { get; set; }
    public Guid? TestId { get; set; }
    public Guid? PackageId { get; set; }
    public Guid? CustomPackageId { get; set; }
    public Guid? FamilyMemberId { get; set; }            // who it's for (ownership-checked)
    public string ItemName { get; set; } = null!;
    public decimal Mrp { get; set; }
    public decimal Price { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public Cart Cart { get; set; } = null!;
}

// commerce.coupons.
public class Coupon
{
    public Guid Id { get; set; }
    public string Code { get; set; } = null!;            // UNIQUE
    public string? Description { get; set; }
    public CouponType Type { get; set; }
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal? MinOrderValue { get; set; }
    public int? TotalUsageLimit { get; set; }
    public int PerUserLimit { get; set; } = 1;
    public int UsedCount { get; set; }
    public DateTimeOffset? ValidFrom { get; set; }
    public DateTimeOffset? ValidUntil { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}

// commerce.payments — Razorpay (HMAC-verified).
public class Payment
{
    public Guid Id { get; set; }
    public Guid BookingId { get; set; }
    public Guid UserId { get; set; }
    public string? RazorpayOrderId { get; set; }
    public string? RazorpayPaymentId { get; set; }
    public string? RazorpaySignature { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public PaymentMethod Method { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Created;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? PaidAt { get; set; }

    public Booking Booking { get; set; } = null!;
}

// commerce.wallets — one per user.
public class Wallet
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public decimal Balance { get; set; }
    public decimal LifetimeEarned { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<WalletTransaction> Transactions { get; set; } = new List<WalletTransaction>();
}

// commerce.wallet_transactions.
public class WalletTransaction
{
    public Guid Id { get; set; }
    public Guid WalletId { get; set; }
    public WalletTransactionType Type { get; set; }
    public WalletTransactionReason Reason { get; set; }
    public decimal Amount { get; set; }
    public decimal BalanceAfter { get; set; }
    public string? ReferenceId { get; set; }             // booking/refund/referral id
    public string? Note { get; set; }
    public Guid? AdjustedByAdminId { get; set; }         // for manual adjustments
    public DateTimeOffset CreatedAt { get; set; }

    public Wallet Wallet { get; set; } = null!;
}

// commerce.refunds — Razorpay reversal + NEFT flow.
public class Refund
{
    public Guid Id { get; set; }
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }
    public Guid UserId { get; set; }
    public decimal Amount { get; set; }
    public RefundMethod Method { get; set; }
    public RefundStatus Status { get; set; } = RefundStatus.Requested;
    public string? Reason { get; set; }
    public string? RazorpayRefundId { get; set; }
    public Guid? ProcessedByAdminId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? ProcessedAt { get; set; }
}

// commerce.cashback_offers.
public class CashbackOffer
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public DiscountType RewardType { get; set; }
    public decimal RewardValue { get; set; }
    public decimal? MaxCashback { get; set; }
    public decimal? MinOrderValue { get; set; }
    public DateTimeOffset? ValidFrom { get; set; }
    public DateTimeOffset? ValidUntil { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}

// commerce.cashbacks — credited cashback ledger.
public class Cashback
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? OfferId { get; set; }
    public Guid? BookingId { get; set; }
    public decimal Amount { get; set; }
    public CashbackStatus Status { get; set; } = CashbackStatus.Pending;
    public DateTimeOffset? CreditAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

// commerce.membership_tiers — tier rules, benefits, multipliers (from DB).
public class MembershipTier
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;            // Silver/Gold/Platinum
    public int SortOrder { get; set; }
    public decimal MinSpend { get; set; }
    public decimal CashbackMultiplier { get; set; } = 1m;
    public decimal DiscountPercent { get; set; }
    public string? BenefitsJson { get; set; }
    public string? BadgeColor { get; set; }
    public bool IsActive { get; set; } = true;
}

// commerce.referrals.
public class Referral
{
    public Guid Id { get; set; }
    public Guid ReferrerUserId { get; set; }
    public Guid? RefereeUserId { get; set; }
    public string Code { get; set; } = null!;
    public string Status { get; set; } = "pending";      // pending|completed
    public decimal RewardAmount { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
