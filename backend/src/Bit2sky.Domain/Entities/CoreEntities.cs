using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// core.family_members (PHI).
public class FamilyMember
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = null!;
    public string Relationship { get; set; } = null!;   // self, spouse, child, parent...
    public DateOnly? DateOfBirth { get; set; }
    public Gender? Gender { get; set; }
    public BloodGroup BloodGroup { get; set; } = BloodGroup.Unknown;
    public string? Mobile { get; set; }
    public bool IsDeleted { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}

// core.addresses (PHI).
public class Address
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public AddressType Type { get; set; } = AddressType.Home;
    public string Line1 { get; set; } = null!;
    public string? Line2 { get; set; }
    public string? Landmark { get; set; }
    public string City { get; set; } = null!;
    public string State { get; set; } = null!;
    public string Pincode { get; set; } = null!;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsDefault { get; set; }
    public bool IsDeleted { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}

// core.audit_logs — IMMUTABLE (no UPDATE/DELETE). Section 4E / 4H.
public class AuditLog
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string? UserRole { get; set; }
    public AuditAction Action { get; set; }
    public string EntityType { get; set; } = null!;
    public string? EntityId { get; set; }
    public string? OldValues { get; set; }              // JSONB before-state
    public string? NewValues { get; set; }              // JSONB after-state
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? CorrelationId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

// core.app_config — every value/label/color/rule (ZERO HARDCODING).
public class AppConfig
{
    public Guid Id { get; set; }
    public string Key { get; set; } = null!;            // UNIQUE
    public string? Value { get; set; }
    public string ValueType { get; set; } = "string";   // string|int|bool|json|color
    public string? Category { get; set; }               // branding|security|feature...
    public string? Description { get; set; }
    public bool IsPublic { get; set; }                  // exposed to public config endpoints
    public DateTimeOffset UpdatedAt { get; set; }
    public Guid? UpdatedBy { get; set; }
}

// core.devices — FCM registration (own device only).
public class Device
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string FcmToken { get; set; } = null!;
    public DevicePlatform Platform { get; set; }
    public string? DeviceModel { get; set; }
    public string? AppVersion { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? LastSeenAt { get; set; }

    public User User { get; set; } = null!;
}

// core.otp_requests — bcrypt-hashed OTP, deleted after 24h (Section 4A / 4F).
public class OtpRequest
{
    public Guid Id { get; set; }
    public string? Mobile { get; set; }                 // null for email-channel OTPs
    public string? Email { get; set; }                  // null for mobile-channel OTPs
    public string OtpHash { get; set; } = null!;        // bcrypt, never plaintext
    public string SessionId { get; set; } = null!;
    public int AttemptCount { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
    public bool IsVerified { get; set; }
    public string? IpAddress { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
