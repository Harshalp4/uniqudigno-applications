using System.Text.Json.Serialization;
using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// core.users — full model (inferred from Section 7 endpoints + Section 4F PHI fields).
// PHI fields (name, mobile, email, date_of_birth) are AES-256-GCM encrypted at rest
// via PhiEncryptionService (applied at the persistence layer).
public class User
{
    public Guid Id { get; set; }

    // ── Profile (PHI) ──────────────────────────────────────────────────────────
    public string? Name { get; set; }
    public string? Mobile { get; set; }                  // E.164, UNIQUE; optional for email/Google sign-up
    public string? Email { get; set; }                   // UNIQUE when present
    public DateOnly? DateOfBirth { get; set; }
    public Gender? Gender { get; set; }
    public string? AvatarUrl { get; set; }

    // ── Account ────────────────────────────────────────────────────────────────
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }                  // soft delete; PHI anonymized
    public bool IsAdminPortalUser { get; set; }          // admin vs app user
    public string? ReferralCode { get; set; }            // own code, UNIQUE
    public Guid? ReferredByUserId { get; set; }
    public Guid? MembershipTierId { get; set; }
    public DateTimeOffset? LastLoginAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // ── Security additions (v3 Section 6) ──────────────────────────────────────
    public DateTimeOffset? OtpLockoutUntil { get; set; }
    public int OtpAttemptCount { get; set; }
    [JsonIgnore] public string? Admin2faSecret { get; set; }          // TOTP secret (encrypted)
    public bool Admin2faEnabled { get; set; }
    [JsonIgnore] public List<string> Admin2faBackupCodes { get; set; } = new();  // hashed (text[])
    public string? LastIpAddress { get; set; }
    public int FailedLoginCount { get; set; }
    public DateTimeOffset? LoginLockedUntil { get; set; }
    [JsonIgnore] public string? PasswordHash { get; set; }            // admin portal users only
    [JsonIgnore] public DateTimeOffset? PasswordChangedAt { get; set; }
    public bool PiiEncrypted { get; set; } = true;

    // ── Navigation ─────────────────────────────────────────────────────────────
    public MembershipTier? MembershipTier { get; set; }
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    [JsonIgnore] public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public ICollection<FamilyMember> FamilyMembers { get; set; } = new List<FamilyMember>();
    public ICollection<Address> Addresses { get; set; } = new List<Address>();
}
