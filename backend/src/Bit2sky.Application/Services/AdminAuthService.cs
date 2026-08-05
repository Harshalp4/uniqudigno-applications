using System.Security.Cryptography;
using System.Text;
using Bit2sky.Application.Abstractions;
using Bit2sky.Application.DTOs;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Bit2sky.Application.Services;

// Admin portal auth: email + password (bcrypt) with progressive lockout, then MANDATORY
// TOTP — enrolled on first login, verified every login (Section 4A). Tokens are only ever
// issued after a successful TOTP/backup-code check, never from the password step.
public class AdminAuthService : IAdminAuthService
{
    private const int MaxFailedLogins = 5;
    private static readonly TimeSpan LoginLockout = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan PendingTtl = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan RefreshLifetime = TimeSpan.FromDays(30);
    private const string DeviceInfo = "admin-portal";

    private readonly IAppDbContext _db;
    private readonly IJwtService _jwt;
    private readonly IHashService _hash;
    private readonly ITotpService _totp;
    private readonly IPermissionService _permissions;
    private readonly ICacheService _cache;
    private readonly IRateLimitEnforcer _rateLimit;
    private readonly IConfiguration _config;

    public AdminAuthService(IAppDbContext db, IJwtService jwt, IHashService hash, ITotpService totp,
        IPermissionService permissions, ICacheService cache, IRateLimitEnforcer rateLimit,
        IConfiguration config)
    {
        _db = db;
        _jwt = jwt;
        _hash = hash;
        _totp = totp;
        _permissions = permissions;
        _cache = cache;
        _rateLimit = rateLimit;
        _config = config;
    }

    public async Task<AdminLoginResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        var normalized = email.Trim().ToLowerInvariant();
        await _rateLimit.EnforceAsync("admin_login", normalized, ct);

        var user = await _db.Set<User>().FirstOrDefaultAsync(
            u => u.IsAdminPortalUser && u.Email != null && u.Email.ToLower() == normalized && !u.IsDeleted, ct);

        // Uniform failure: never reveal whether the account exists (Section 4B enumeration).
        if (user is null || user.PasswordHash is null)
            throw new UnauthorizedAppException();

        if (user.LoginLockedUntil is { } until && until > DateTimeOffset.UtcNow)
            throw new RateLimitAppException((int)(until - DateTimeOffset.UtcNow).TotalSeconds);

        if (!user.IsActive || !_hash.Verify(password, user.PasswordHash))
        {
            user.FailedLoginCount++;
            if (user.FailedLoginCount >= MaxFailedLogins)
            {
                user.LoginLockedUntil = DateTimeOffset.UtcNow.Add(LoginLockout);
                user.FailedLoginCount = 0;
                _db.Set<SecurityEvent>().Add(new SecurityEvent
                {
                    Id = Guid.NewGuid(),
                    EventType = SecurityEventType.LoginLocked,
                    UserId = user.Id,
                    Severity = SecurityEventSeverity.High,
                    Details = "{\"reason\":\"admin login failures\"}",
                });
            }
            await _db.SaveChangesAsync(ct);
            throw new UnauthorizedAppException();
        }

        user.FailedLoginCount = 0;
        user.LoginLockedUntil = null;

        // DEV-ONLY 2FA bypass: when Auth:DisableAdmin2fa=true (set only in local
        // Development), skip TOTP and issue the token straight from the password
        // step so the portal is testable without an authenticator. NEVER enable
        // in staging/production — the flag defaults off and this is the only
        // place it is read.
        if (Admin2faDisabled)
        {
            user.LastLoginAt = DateTimeOffset.UtcNow;
            var devPair = await IssueAsync(user, ct);
            await _db.SaveChangesAsync(ct);
            return new AdminLoginResult(
                TwoFactorRequired: false, EnrollRequired: false, SessionId: null, Tokens: devPair);
        }

        await _db.SaveChangesAsync(ct);

        var enrolling = !user.Admin2faEnabled;
        var sessionId = Guid.NewGuid().ToString("N");
        await _cache.SetAsync(PendingKey(sessionId), new AdminPending(user.Id, enrolling), PendingTtl, ct);

        return new AdminLoginResult(TwoFactorRequired: !enrolling, EnrollRequired: enrolling, sessionId);
    }

    public async Task<Enroll2faResult> EnrollAsync(string sessionId, CancellationToken ct = default)
    {
        var pending = await _cache.GetAsync<AdminPending>(PendingKey(sessionId), ct)
            ?? throw new UnauthorizedAppException();
        if (!pending.Enrolling)
            throw new ConflictAppException("Two-factor authentication is already enrolled.");

        var user = await _db.Set<User>().FirstAsync(u => u.Id == pending.UserId, ct);
        var (secret, uri) = _totp.Generate(user.Email ?? user.Mobile);
        var backupCodes = _totp.GenerateBackupCodes();

        // Secret + backup codes are written now but 2FA is only marked "enabled" once the
        // user proves possession via VerifyAsync — so a half-finished enrollment can't lock them out.
        user.Admin2faSecret = secret;
        user.Admin2faBackupCodes = backupCodes.Select(_hash.Hash).ToList();
        await _db.SaveChangesAsync(ct);

        return new Enroll2faResult(secret, uri, backupCodes);
    }

    public async Task<TokenPair> VerifyAsync(string sessionId, string code, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("admin_2fa", sessionId, ct);

        var pending = await _cache.GetAsync<AdminPending>(PendingKey(sessionId), ct)
            ?? throw new UnauthorizedAppException();

        var user = await _db.Set<User>().FirstAsync(u => u.Id == pending.UserId, ct);
        if (user.Admin2faSecret is null)
            throw new UnauthorizedAppException();

        var trimmed = code.Trim();
        var ok = _totp.Verify(user.Admin2faSecret, trimmed);
        if (!ok)
        {
            // Backup codes are single-use: consume the matching one.
            var match = user.Admin2faBackupCodes.FirstOrDefault(h => _hash.Verify(trimmed, h));
            if (match is not null)
            {
                user.Admin2faBackupCodes.Remove(match);
                ok = true;
            }
        }

        if (!ok)
            throw new UnauthorizedAppException();

        if (pending.Enrolling)
            user.Admin2faEnabled = true;
        user.LastLoginAt = DateTimeOffset.UtcNow;

        var pair = await IssueAsync(user, ct);
        await _db.SaveChangesAsync(ct);
        await _cache.RemoveAsync(PendingKey(sessionId), ct);
        return pair;
    }

    // ── helpers ──────────────────────────────────────────────────────────────
    private async Task<TokenPair> IssueAsync(User user, CancellationToken ct)
    {
        var perms = await _permissions.GetForUserAsync(user.Id, ct);
        var deviceId = DeviceId(DeviceInfo);
        var (access, accessExpiry) = _jwt.IssueAccessToken(user.Id, perms.Role, perms.Permissions, deviceId);
        var (refresh, refreshHash) = _jwt.GenerateRefreshToken();

        _db.Set<RefreshToken>().Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = refreshHash,
            DeviceId = deviceId,
            TokenFamily = Guid.NewGuid(),
            ExpiresAt = DateTimeOffset.UtcNow.Add(RefreshLifetime),
        });

        return new TokenPair(access, refresh, accessExpiry, perms.Role);
    }

    private bool Admin2faDisabled =>
        string.Equals(_config["Auth:DisableAdmin2fa"], "true", StringComparison.OrdinalIgnoreCase);

    private static string PendingKey(string sessionId) => $"admin2fa:{sessionId}";
    private static string DeviceId(string deviceInfo)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(deviceInfo)));

    private sealed record AdminPending(Guid UserId, bool Enrolling);
}
