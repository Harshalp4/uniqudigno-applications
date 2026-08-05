using Bit2sky.Application.Abstractions;
using StackExchange.Redis;

namespace Bit2sky.Infrastructure.Caching;

// Distributed sliding-window rate limiter backed by a Redis sorted set per key
// (Section 4B). Each request is a member scored by timestamp; entries older than the
// window are trimmed before counting.
public class RedisRateLimitService : IRateLimitService
{
    private readonly IConnectionMultiplexer _redis;

    public RedisRateLimitService(IConnectionMultiplexer redis) => _redis = redis;

    public async Task<(bool Allowed, int RetryAfterSeconds)> CheckAsync(
        string key, int limit, TimeSpan window, CancellationToken ct = default)
    {
        if (!_redis.IsConnected)
            return (true, 0); // degrade open if Redis is unreachable; WAF backs this up

        var db = _redis.GetDatabase();
        var redisKey = $"ratelimit:{key}";
        var now = DateTimeOffset.UtcNow;
        var windowStart = now.Subtract(window).ToUnixTimeMilliseconds();
        var nowMs = now.ToUnixTimeMilliseconds();

        await db.SortedSetRemoveRangeByScoreAsync(redisKey, 0, windowStart);
        var count = await db.SortedSetLengthAsync(redisKey);

        if (count >= limit)
        {
            var oldest = await db.SortedSetRangeByRankWithScoresAsync(redisKey, 0, 0);
            var retryAfter = (int)window.TotalSeconds;
            if (oldest.Length > 0)
            {
                var resetAt = (long)oldest[0].Score + (long)window.TotalMilliseconds;
                retryAfter = Math.Max(1, (int)((resetAt - nowMs) / 1000));
            }
            return (false, retryAfter);
        }

        await db.SortedSetAddAsync(redisKey, Guid.NewGuid().ToString(), nowMs);
        await db.KeyExpireAsync(redisKey, window);
        return (true, 0);
    }
}
