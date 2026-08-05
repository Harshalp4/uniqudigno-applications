using System.ComponentModel.DataAnnotations;

namespace Bit2sky.Application.DTOs;

public record SendOtpRequest([Required] string Mobile);
// DevOtp is populated only when Auth:EchoEmailOtp is on (dev, no mail provider).
public record SendOtpResult(string SessionId, int ExpirySeconds, string? DevOtp = null);

// Email-channel login (mobile optional). Verify reuses VerifyOtpRequest.
// Email is validated for format so malformed addresses can't create junk accounts.
public record SendEmailOtpRequest([Required, EmailAddress] string Email);
public record GoogleLoginRequest(string IdToken, string DeviceInfo);

public record VerifyOtpRequest(string SessionId, string Otp, string DeviceInfo);
public record TokenPair(string AccessToken, string RefreshToken, DateTimeOffset AccessTokenExpiresAt, string Role);

public record RefreshRequest(string RefreshToken, string DeviceInfo);

public record MePermissions(string Role, IReadOnlyCollection<string> Permissions, bool IsAdminPortalUser);
