using Bit2sky.Application.Abstractions;
using Bit2sky.Shared;

namespace Bit2sky.Application.Services;

public interface IRateLimitEnforcer
{
    // Throws RateLimitAppException (429) if the named policy is exceeded for the discriminator.
    Task EnforceAsync(string policy, string discriminator, CancellationToken ct = default);
}

// Maps endpoint groups to Section 4B limits and enforces them via the distributed limiter.
public class RateLimitService : IRateLimitEnforcer
{
    // policy → (limit, window)
    private static readonly Dictionary<string, (int Limit, TimeSpan Window)> Policies = new()
    {
        ["otp_send_mobile"] = (3, TimeSpan.FromMinutes(10)),
        ["otp_send_ip"] = (5, TimeSpan.FromMinutes(10)),
        ["otp_verify"] = (5, TimeSpan.FromMinutes(5)),
        ["token_refresh"] = (20, TimeSpan.FromMinutes(1)),
        ["google_auth"] = (10, TimeSpan.FromMinutes(1)),
        ["ai_message"] = (20, TimeSpan.FromHours(1)),
        ["ai_session"] = (10, TimeSpan.FromHours(1)),
        ["booking_create"] = (10, TimeSpan.FromMinutes(1)),
        ["cart_add"] = (30, TimeSpan.FromMinutes(1)),
        ["support_create"] = (5, TimeSpan.FromHours(1)),
        ["reports_read"] = (30, TimeSpan.FromMinutes(1)),
        ["catalogue_read"] = (60, TimeSpan.FromMinutes(1)),
        ["public_read"] = (100, TimeSpan.FromMinutes(1)),
        ["admin"] = (100, TimeSpan.FromMinutes(1)),
        ["broadcast"] = (2, TimeSpan.FromHours(1)),
        ["webhook"] = (200, TimeSpan.FromMinutes(1)),
    };

    private readonly IRateLimitService _limiter;

    public RateLimitService(IRateLimitService limiter) => _limiter = limiter;

    public async Task EnforceAsync(string policy, string discriminator, CancellationToken ct = default)
    {
        if (!Policies.TryGetValue(policy, out var p)) return;
        var (allowed, retryAfter) = await _limiter.CheckAsync($"{policy}:{discriminator}", p.Limit, p.Window, ct);
        if (!allowed) throw new RateLimitAppException(retryAfter);
    }
}
