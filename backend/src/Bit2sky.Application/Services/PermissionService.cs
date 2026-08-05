using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Section 3C #1/#3: load permissions from DB, cache in Redis (5-min TTL).
public class PermissionService : IPermissionService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(5);
    private readonly IAppDbContext _db;
    private readonly ICacheService _cache;

    public PermissionService(IAppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    private static string CacheKey(Guid userId) => $"perm:{userId}";

    public async Task<UserPermissions> GetForUserAsync(Guid userId, CancellationToken ct = default)
    {
        var cached = await _cache.GetAsync<UserPermissions>(CacheKey(userId), ct);
        if (cached is not null) return cached;

        var roleIds = await _db.Set<UserRole>()
            .Where(ur => ur.UserId == userId)
            .Select(ur => ur.RoleId)
            .ToListAsync(ct);

        var role = await _db.Set<Role>()
            .Where(r => roleIds.Contains(r.Id))
            .OrderBy(r => r.Name)
            .Select(r => r.Name)
            .FirstOrDefaultAsync(ct) ?? "customer";

        var permissions = await _db.Set<RolePermission>()
            .Where(rp => roleIds.Contains(rp.RoleId))
            .Select(rp => rp.Permission.Code)
            .Distinct()
            .ToListAsync(ct);

        var isAdminPortal = await _db.Set<User>()
            .Where(u => u.Id == userId)
            .Select(u => u.IsAdminPortalUser)
            .FirstOrDefaultAsync(ct);

        var result = new UserPermissions(role, permissions, isAdminPortal);
        await _cache.SetAsync(CacheKey(userId), result, CacheTtl, ct);
        return result;
    }

    public async Task<bool> HasPermissionAsync(Guid userId, string permission, CancellationToken ct = default)
    {
        var perms = await GetForUserAsync(userId, ct);
        return perms.Permissions.Contains(permission);
    }

    public Task InvalidateAsync(Guid userId, CancellationToken ct = default)
        => _cache.RemoveAsync(CacheKey(userId), ct);
}
