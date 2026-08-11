using System.Net.Http;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Application.DTOs;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Bit2sky.Application.Services;

// OTP auth, RS256 issuance, refresh-token rotation + reuse detection (Section 4A).
public class AuthService : IAuthService
{
    private static readonly TimeSpan OtpExpiry = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan RefreshLifetime = TimeSpan.FromDays(30);

    private readonly IAppDbContext _db;
    private readonly IJwtService _jwt;
    private readonly IHashService _hash;
    private readonly IRateLimitEnforcer _rateLimit;
    private readonly IPermissionService _permissions;
    private readonly ICacheService _cache;
    private readonly IEmailSender _email;
    private readonly IHttpClientFactory _httpFactory;
    private readonly IConfiguration _config;

    public AuthService(IAppDbContext db, IJwtService jwt, IHashService hash,
        IRateLimitEnforcer rateLimit, IPermissionService permissions, ICacheService cache,
        IEmailSender email, IHttpClientFactory httpFactory, IConfiguration config)
    {
        _db = db;
        _jwt = jwt;
        _hash = hash;
        _rateLimit = rateLimit;
        _permissions = permissions;
        _cache = cache;
        _email = email;
        _httpFactory = httpFactory;
        _config = config;
    }

    public async Task<SendOtpResult> SendOtpAsync(string mobile, string ip, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("otp_send_mobile", mobile, ct);
        await _rateLimit.EnforceAsync("otp_send_ip", ip, ct);

        var lockUntil = await _cache.GetAsync<DateTimeOffset?>(LockKey(mobile), ct);
        if (lockUntil is { } until && until > DateTimeOffset.UtcNow)
            throw new RateLimitAppException((int)(until - DateTimeOffset.UtcNow).TotalSeconds);

        var otp = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var sessionId = Guid.NewGuid().ToString("N");

        _db.Set<OtpRequest>().Add(new OtpRequest
        {
            Id = Guid.NewGuid(),
            Mobile = mobile,
            OtpHash = _hash.Hash(otp),
            SessionId = sessionId,
            ExpiresAt = DateTimeOffset.UtcNow.Add(OtpExpiry),
            IpAddress = ip,
        });
        await _db.SaveChangesAsync(ct);

        // OTP delivery (WhatsApp-first, SMS fallback) handled by NotificationOrchestrator.
        // Never log or return the OTP value (Section 4H).
        return new SendOtpResult(sessionId, (int)OtpExpiry.TotalSeconds);
    }

    public async Task<TokenPair> VerifyOtpAsync(string sessionId, string otp, string deviceInfo, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("otp_verify", sessionId, ct);

        var request = await _db.Set<OtpRequest>()
            .Where(o => o.SessionId == sessionId && !o.IsVerified)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync(ct)
            ?? throw new UnauthorizedAppException();

        if (request.ExpiresAt < DateTimeOffset.UtcNow)
            throw new UnauthorizedAppException();

        if (!_hash.Verify(otp, request.OtpHash))
        {
            request.AttemptCount++;
            await ApplyProgressiveLockoutAsync(request.Mobile, request.AttemptCount, ct);
            await _db.SaveChangesAsync(ct);
            throw new UnauthorizedAppException();
        }

        request.IsVerified = true;

        var user = await _db.Set<User>().FirstOrDefaultAsync(u => u.Mobile == request.Mobile, ct);
        if (user is null)
        {
            user = new User { Id = Guid.NewGuid(), Mobile = request.Mobile, ReferralCode = NewReferralCode() };
            _db.Set<User>().Add(user);
        }
        user.LastLoginAt = DateTimeOffset.UtcNow;
        user.OtpAttemptCount = 0;

        var pair = await IssueAsync(user, deviceInfo, Guid.NewGuid(), ct);
        await _db.SaveChangesAsync(ct);
        return pair;
    }

    // ── Email-channel login (mobile optional) ────────────────────────────────
    public async Task<SendOtpResult> SendEmailOtpAsync(string email, string ip, CancellationToken ct = default)
    {
        email = email.Trim().ToLowerInvariant();
        await _rateLimit.EnforceAsync("otp_send_email", email, ct);
        await _rateLimit.EnforceAsync("otp_send_ip", ip, ct);

        var otp = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var sessionId = Guid.NewGuid().ToString("N");

        _db.Set<OtpRequest>().Add(new OtpRequest
        {
            Id = Guid.NewGuid(),
            Email = email,
            OtpHash = _hash.Hash(otp),
            SessionId = sessionId,
            ExpiresAt = DateTimeOffset.UtcNow.Add(OtpExpiry),
            IpAddress = ip,
        });
        await _db.SaveChangesAsync(ct);

        // The reviewer address never receives mail — it logs in with the fixed
        // reviewer code (see VerifyEmailOtpAsync), so skip the send for it.
        var reviewerEmail = _config["Auth:ReviewerEmail"];
        var isReviewer = !string.IsNullOrWhiteSpace(reviewerEmail)
            && string.Equals(email, reviewerEmail, StringComparison.OrdinalIgnoreCase);
        if (!isReviewer) await _email.SendOtpAsync(email, otp, ct);
        // Dev affordance when no mail provider is wired: echo the OTP so it can
        // be entered without an inbox. Never enable in production.
        var echo = string.Equals(_config["Auth:EchoEmailOtp"], "true", StringComparison.OrdinalIgnoreCase);
        return new SendOtpResult(sessionId, (int)OtpExpiry.TotalSeconds, echo ? otp : null);
    }

    public async Task<TokenPair> VerifyEmailOtpAsync(string sessionId, string otp, string deviceInfo, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("otp_verify", sessionId, ct);

        var request = await _db.Set<OtpRequest>()
            .Where(o => o.SessionId == sessionId && !o.IsVerified && o.Email != null)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync(ct)
            ?? throw new UnauthorizedAppException();

        if (request.ExpiresAt < DateTimeOffset.UtcNow) throw new UnauthorizedAppException();

        // Store-review bypass: a fixed reviewer email + code that verifies without
        // a real inbox, so Google's tester can get past the login wall. Active only
        // when BOTH Auth:ReviewerEmail and Auth:ReviewerOtp are configured (env);
        // remove/rotate them once the app is approved.
        var reviewerEmail = _config["Auth:ReviewerEmail"];
        var reviewerOtp = _config["Auth:ReviewerOtp"];
        var isReviewer = !string.IsNullOrWhiteSpace(reviewerEmail)
            && !string.IsNullOrWhiteSpace(reviewerOtp)
            && string.Equals(request.Email, reviewerEmail, StringComparison.OrdinalIgnoreCase)
            && otp == reviewerOtp;

        if (!isReviewer && !_hash.Verify(otp, request.OtpHash))
        {
            request.AttemptCount++;
            await _db.SaveChangesAsync(ct);
            throw new UnauthorizedAppException();
        }
        request.IsVerified = true;

        var user = await FindOrCreateByEmailAsync(request.Email!, ct);
        var pair = await IssueAsync(user, deviceInfo, Guid.NewGuid(), ct);
        await _db.SaveChangesAsync(ct);
        return pair;
    }

    public async Task<TokenPair> LoginWithGoogleAsync(string idToken, string deviceInfo, CancellationToken ct = default)
    {
        var email = await ValidateGoogleTokenAsync(idToken, ct)
            ?? throw new UnauthorizedAppException();
        var user = await FindOrCreateByEmailAsync(email, ct);
        var pair = await IssueAsync(user, deviceInfo, Guid.NewGuid(), ct);
        await _db.SaveChangesAsync(ct);
        return pair;
    }

    private async Task<User> FindOrCreateByEmailAsync(string email, CancellationToken ct)
    {
        email = email.Trim().ToLowerInvariant();
        var user = await _db.Set<User>().FirstOrDefaultAsync(u => u.Email == email, ct);
        if (user is null)
        {
            user = new User { Id = Guid.NewGuid(), Email = email, ReferralCode = NewReferralCode() };
            _db.Set<User>().Add(user);
        }
        user.LastLoginAt = DateTimeOffset.UtcNow;
        return user;
    }

    // Validates a Google ID token via Google's public tokeninfo endpoint and
    // returns the verified email. Robust to email_verified arriving as a bool or
    // a string, and accepts any OAuth client id from our Google project (the
    // audience may be the web client or an Android client). Logs the rejection
    // reason so failures are diagnosable from the host logs.
    private async Task<string?> ValidateGoogleTokenAsync(string idToken, CancellationToken ct)
    {
        try
        {
            var http = _httpFactory.CreateClient();
            var resp = await http.GetAsync(
                $"https://oauth2.googleapis.com/tokeninfo?id_token={Uri.EscapeDataString(idToken)}", ct);
            if (!resp.IsSuccessStatusCode)
            {
                Console.WriteLine($"[GoogleAuth] tokeninfo returned HTTP {(int)resp.StatusCode}");
                return null;
            }

            using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync(ct));
            var root = doc.RootElement;

            var email = root.TryGetProperty("email", out var emailEl) ? emailEl.GetString() : null;
            if (string.IsNullOrEmpty(email)) { Console.WriteLine("[GoogleAuth] token has no email"); return null; }

            // email_verified may arrive as boolean true or the string "true".
            var verified = root.TryGetProperty("email_verified", out var evEl)
                && (evEl.ValueKind == JsonValueKind.True
                    || (evEl.ValueKind == JsonValueKind.String
                        && string.Equals(evEl.GetString(), "true", StringComparison.OrdinalIgnoreCase)));
            if (!verified) { Console.WriteLine("[GoogleAuth] email not verified"); return null; }

            var iss = root.TryGetProperty("iss", out var issEl) ? issEl.GetString() : null;
            if (iss is not ("accounts.google.com" or "https://accounts.google.com"))
            {
                Console.WriteLine($"[GoogleAuth] unexpected iss: {iss}");
                return null;
            }

            // Accept any client id from our Google project. The configured value is
            // the web client; its numeric prefix (e.g. "381464039988-") identifies
            // the project, so an Android-client audience from the same project passes.
            var aud = root.TryGetProperty("aud", out var audEl) ? audEl.GetString() : null;
            var expectedAud = _config["Auth:GoogleClientId"];
            if (!string.IsNullOrEmpty(expectedAud) && !string.IsNullOrEmpty(aud))
            {
                var dash = expectedAud.IndexOf('-');
                var prefix = dash > 0 ? expectedAud[..(dash + 1)] : expectedAud;
                if (aud != expectedAud && !aud.StartsWith(prefix, StringComparison.Ordinal))
                {
                    Console.WriteLine($"[GoogleAuth] aud not in project: got {aud}, expected {expectedAud}");
                    return null;
                }
            }

            return email;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GoogleAuth] validation error: {ex.Message}");
            return null;
        }
    }

    public async Task<TokenPair> TechnicianLoginAsync(string employeeId, string password, string ip, CancellationToken ct = default)
    {
        var id = employeeId.Trim();
        await _rateLimit.EnforceAsync("technician_login", id, ct);

        var tech = await _db.Set<Technician>()
            .FirstOrDefaultAsync(t => t.EmployeeId == id && t.IsActive, ct);

        // Uniform failure regardless of which check fails (Section 4B enumeration).
        if (tech is null || tech.PasswordHash is null || tech.UserId is null)
            throw new UnauthorizedAppException();

        if (tech.LoginLockedUntil is { } until && until > DateTimeOffset.UtcNow)
            throw new RateLimitAppException((int)(until - DateTimeOffset.UtcNow).TotalSeconds);

        if (!_hash.Verify(password, tech.PasswordHash))
        {
            tech.FailedLoginCount++;
            if (tech.FailedLoginCount >= 5)
            {
                tech.LoginLockedUntil = DateTimeOffset.UtcNow.AddMinutes(15);
                tech.FailedLoginCount = 0;
            }
            await _db.SaveChangesAsync(ct);
            throw new UnauthorizedAppException();
        }

        tech.FailedLoginCount = 0;
        tech.LoginLockedUntil = null;
        tech.LastLoginAt = DateTimeOffset.UtcNow;

        var user = await _db.Set<User>().FirstAsync(u => u.Id == tech.UserId, ct);
        user.LastLoginAt = DateTimeOffset.UtcNow;

        // Device bound to the employee id so refresh-token rotation stays per-device.
        var pair = await IssueAsync(user, $"technician:{id}", Guid.NewGuid(), ct);
        await _db.SaveChangesAsync(ct);
        return pair;
    }

    public async Task<TokenPair> RefreshAsync(string refreshToken, string deviceInfo, CancellationToken ct = default)
    {
        var hash = _jwt.HashRefreshToken(refreshToken);
        var token = await _db.Set<RefreshToken>().FirstOrDefaultAsync(t => t.TokenHash == hash, ct)
            ?? throw new UnauthorizedAppException();

        await _rateLimit.EnforceAsync("token_refresh", token.UserId.ToString(), ct);

        // Rotation grace: the client may retry with the just-rotated token when it
        // was killed (or lost the network) before persisting the new pair. Within
        // the window this is a race, not theft — issue a fresh pair from the same
        // family. ReusedAt stays null so a *second* replay still trips detection.
        if (token.RevokedAt is not null
            && token.ReusedAt is null
            && !token.IsTheftDetected
            // Only rotation leaves a successor hash; logout / family revocation
            // must never be forgiven by the grace window.
            && token.ReplacedByTokenHash is not null
            && token.DeviceId == DeviceId(deviceInfo)
            && DateTimeOffset.UtcNow - token.RevokedAt < TimeSpan.FromSeconds(60))
        {
            token.ReusedAt = DateTimeOffset.UtcNow;
            // The successor issued by the lost rotation was never persisted by
            // the client — revoke it so the family keeps a single live token.
            if (token.ReplacedByTokenHash is not null)
            {
                var orphan = await _db.Set<RefreshToken>().FirstOrDefaultAsync(
                    t => t.TokenHash == token.ReplacedByTokenHash && t.RevokedAt == null, ct);
                if (orphan is not null) orphan.RevokedAt = DateTimeOffset.UtcNow;
            }
            var graceUser = await _db.Set<User>().FirstAsync(u => u.Id == token.UserId, ct);
            var gracePair = await IssueAsync(graceUser, deviceInfo, token.TokenFamily, ct, replaces: token);
            await _db.SaveChangesAsync(ct);
            return gracePair;
        }

        // Reuse detection: a revoked token presented again ⇒ revoke the whole family.
        if (token.RevokedAt is not null)
        {
            token.IsTheftDetected = true;
            token.ReusedAt = DateTimeOffset.UtcNow;
            await RevokeFamilyAsync(token.TokenFamily, ct);
            _db.Set<SecurityEvent>().Add(new SecurityEvent
            {
                Id = Guid.NewGuid(),
                EventType = SecurityEventType.TokenReuseDetected,
                UserId = token.UserId,
                Severity = SecurityEventSeverity.Critical,
                Details = "{\"reason\":\"refresh token reuse\"}",
            });
            await _db.SaveChangesAsync(ct);
            throw new UnauthorizedAppException();
        }

        if (token.ExpiresAt < DateTimeOffset.UtcNow)
            throw new UnauthorizedAppException();

        if (token.DeviceId != DeviceId(deviceInfo))
            throw new UnauthorizedAppException(); // device changed ⇒ full re-auth

        var user = await _db.Set<User>().FirstAsync(u => u.Id == token.UserId, ct);

        token.RevokedAt = DateTimeOffset.UtcNow;
        var pair = await IssueAsync(user, deviceInfo, token.TokenFamily, ct, replaces: token);
        await _db.SaveChangesAsync(ct);
        return pair;
    }

    public async Task LogoutAsync(string refreshToken, CancellationToken ct = default)
    {
        var hash = _jwt.HashRefreshToken(refreshToken);
        var token = await _db.Set<RefreshToken>().FirstOrDefaultAsync(t => t.TokenHash == hash, ct);
        if (token is { RevokedAt: null })
        {
            token.RevokedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task LogoutAllAsync(Guid userId, CancellationToken ct = default)
    {
        var tokens = await _db.Set<RefreshToken>()
            .Where(t => t.UserId == userId && t.RevokedAt == null).ToListAsync(ct);
        foreach (var t in tokens) t.RevokedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
    }

    public async Task<MePermissions> GetPermissionsAsync(Guid userId, CancellationToken ct = default)
    {
        var p = await _permissions.GetForUserAsync(userId, ct);
        return new MePermissions(p.Role, p.Permissions, p.IsAdminPortalUser);
    }

    // ── helpers ──────────────────────────────────────────────────────────────
    private async Task<TokenPair> IssueAsync(User user, string deviceInfo, Guid family,
        CancellationToken ct, RefreshToken? replaces = null)
    {
        var perms = await _permissions.GetForUserAsync(user.Id, ct);
        var deviceId = DeviceId(deviceInfo);
        var (access, accessExpiry) = _jwt.IssueAccessToken(user.Id, perms.Role, perms.Permissions, deviceId);
        var (refresh, refreshHash) = _jwt.GenerateRefreshToken();

        var entity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = refreshHash,
            DeviceId = deviceId,
            TokenFamily = family,
            ExpiresAt = DateTimeOffset.UtcNow.Add(RefreshLifetime),
        };
        _db.Set<RefreshToken>().Add(entity);
        if (replaces is not null) replaces.ReplacedByTokenHash = refreshHash;

        return new TokenPair(access, refresh, accessExpiry, perms.Role);
    }

    private async Task RevokeFamilyAsync(Guid family, CancellationToken ct)
    {
        var tokens = await _db.Set<RefreshToken>()
            .Where(t => t.TokenFamily == family && t.RevokedAt == null).ToListAsync(ct);
        foreach (var t in tokens) t.RevokedAt = DateTimeOffset.UtcNow;
    }

    private async Task ApplyProgressiveLockoutAsync(string mobile, int attempts, CancellationToken ct)
    {
        TimeSpan? duration = attempts switch
        {
            >= 10 => TimeSpan.FromHours(24),
            >= 5 => TimeSpan.FromMinutes(15),
            >= 3 => TimeSpan.FromMinutes(2),
            _ => null,
        };
        if (duration is { } d)
            await _cache.SetAsync(LockKey(mobile), DateTimeOffset.UtcNow.Add(d), d, ct);
    }

    private static string LockKey(string mobile) => $"otplock:{mobile}";
    private static string DeviceId(string deviceInfo)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(deviceInfo)));
    private static string NewReferralCode()
        => "B2S" + Convert.ToHexString(RandomNumberGenerator.GetBytes(4));
}
