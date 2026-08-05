using System.Security.Claims;

namespace Bit2sky.Application.Abstractions;

// Token issuance (RS256) + JWKS exposure.
public interface IJwtService
{
    (string AccessToken, DateTimeOffset ExpiresAt) IssueAccessToken(
        Guid userId, string role, IEnumerable<string> permissions, string deviceId);

    (string Token, string TokenHash) GenerateRefreshToken();
    string HashRefreshToken(string token);
    string GetJwksJson();
}

// AES-256-GCM field encryption for PHI at rest (Section 4F).
public interface IPhiEncryptionService
{
    string Encrypt(string plaintext);
    string Decrypt(string ciphertext);
}

// Admin TOTP 2FA (Section 4A).
public interface ITotpService
{
    (string Secret, string OtpAuthUri) Generate(string accountName);
    bool Verify(string secret, string code);
    IReadOnlyList<string> GenerateBackupCodes(int count = 8);
}

// Azure Key Vault secret access (Managed Identity).
public interface IKeyVaultService
{
    Task<string?> GetSecretAsync(string name, CancellationToken ct = default);
}

// One-way hashing for OTPs / passwords (bcrypt).
public interface IHashService
{
    string Hash(string value);
    bool Verify(string value, string hash);
}

// Distributed cache (Redis L2).
public interface ICacheService
{
    Task<T?> GetAsync<T>(string key, CancellationToken ct = default);
    Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken ct = default);
    Task RemoveAsync(string key, CancellationToken ct = default);
}

// Distributed sliding-window rate limiting (Section 4B groups).
public interface IRateLimitService
{
    // Returns true if allowed; false if the limit is exceeded (with retry-after seconds).
    Task<(bool Allowed, int RetryAfterSeconds)> CheckAsync(
        string key, int limit, TimeSpan window, CancellationToken ct = default);
}

// Input hardening: HTML strip, SSRF allowlist, MIME magic-byte validation, injection strip.
public interface IInputSanitizationService
{
    string StripHtml(string input);
    string SanitizeRichHtml(string html);
    bool IsUrlAllowed(string url);
    bool IsAllowedFile(ReadOnlySpan<byte> content, string declaredMime, long maxBytes, out string detectedMime);
    string StripPromptInjection(string message);
}

// Ambient authenticated principal.
public interface ICurrentUser
{
    Guid? UserId { get; }
    string? Role { get; }
    bool IsAuthenticated { get; }
    bool IsAdminPortalUser { get; }
    IReadOnlyCollection<string> Permissions { get; }
    bool HasPermission(string permission);
    ClaimsPrincipal? Principal { get; }
}
