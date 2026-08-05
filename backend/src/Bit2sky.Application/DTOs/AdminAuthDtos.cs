namespace Bit2sky.Application.DTOs;

public record AdminLoginRequest(string Email, string Password);

/// Outcome of admin step-1. Normally tokens are never returned here — the client
/// must complete enrollment (first login) or verification. [Tokens] is populated
/// ONLY under the dev-only Auth:DisableAdmin2fa bypass (SessionId is null then).
public record AdminLoginResult(
    bool TwoFactorRequired, bool EnrollRequired, string? SessionId, TokenPair? Tokens = null);

public record Enroll2faRequest(string SessionId);
public record Enroll2faResult(string Secret, string OtpAuthUri, IReadOnlyList<string> BackupCodes);

public record Admin2faVerifyRequest(string SessionId, string Code);

public record TechnicianLoginRequest(string EmployeeId, string Password);
