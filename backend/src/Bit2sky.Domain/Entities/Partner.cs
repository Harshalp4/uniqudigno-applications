using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// admin.partners — referral/booking partners (app users, API-enforced).
public class Partner
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string Name { get; set; } = null!;
    public string Mobile { get; set; } = null!;
    public string? Email { get; set; }
    public PartnerType Type { get; set; } = PartnerType.Individual;
    public PartnerStatus Status { get; set; } = PartnerStatus.Pending;
    public decimal CommissionPercent { get; set; }
    public string? BankAccountJson { get; set; }         // payout details (sensitive)
    public string? GstNumber { get; set; }
    public Guid? VerifiedByAdminId { get; set; }
    public DateTimeOffset? VerifiedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

// admin.partner_commissions — per-booking commission ledger.
public class PartnerCommission
{
    public Guid Id { get; set; }
    public Guid PartnerId { get; set; }
    public Guid BookingId { get; set; }
    public decimal BookingAmount { get; set; }
    public decimal CommissionAmount { get; set; }
    public string Status { get; set; } = "accrued";      // accrued|paid
    public Guid? PayoutId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
