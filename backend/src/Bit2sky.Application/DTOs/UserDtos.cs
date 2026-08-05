using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;

namespace Bit2sky.Application.DTOs;

public record UpdateMeRequest(string? Name, string? Email, DateOnly? DateOfBirth, Gender? Gender, string? Mobile);

// Client-safe projection of the current user for GET/PUT /users/me.
// NEVER expose PasswordHash, RefreshTokens, Admin2faSecret/BackupCodes, or the
// internal security counters — see UserProfileDto.FromEntity for the allowlist.
public record UserProfileDto(
    Guid Id,
    string? Name,
    string? Mobile,
    string? Email,
    DateOnly? DateOfBirth,
    Gender? Gender,
    string? AvatarUrl,
    string? ReferralCode,
    Guid? MembershipTierId,
    bool IsActive,
    DateTimeOffset? LastLoginAt,
    DateTimeOffset CreatedAt)
{
    public static UserProfileDto FromEntity(User u) => new(
        u.Id, u.Name, u.Mobile, u.Email, u.DateOfBirth, u.Gender, u.AvatarUrl,
        u.ReferralCode, u.MembershipTierId, u.IsActive, u.LastLoginAt, u.CreatedAt);
}

public record FamilyMemberRequest(string Name, string Relationship, DateOnly? DateOfBirth, Gender? Gender, BloodGroup BloodGroup, string? Mobile);

public record AddressRequest(AddressType Type, string Line1, string? Line2, string? Landmark, string City, string State, string Pincode, double? Latitude, double? Longitude);

// Role-shaped user views (Section 3C #6). Phone masked unless caller has users.view_pii.
public record AdminUserDto(Guid Id, string? Name, string Mobile, string? Email, DateOnly? DateOfBirth, bool IsActive, DateTimeOffset CreatedAt);
public record SupportUserDto(Guid Id, string? Name, string Mobile, bool IsActive);     // masked phone, no DOB
public record PublicUserDto(Guid Id, string? Name);

public record DashboardDto(string? Name, int UpcomingBookings, int ReportsReady, int? HealthScore, decimal WalletBalance);
