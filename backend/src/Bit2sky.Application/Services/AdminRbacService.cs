using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Roles & permissions management (Section 3D / 11). Permission changes invalidate
// the affected users' Redis cache.
public class AdminRbacService : IAdminRbacService
{
    private readonly IAppDbContext _db;
    private readonly IPermissionService _permissions;

    public AdminRbacService(IAppDbContext db, IPermissionService permissions)
    {
        _db = db;
        _permissions = permissions;
    }

    public async Task<IReadOnlyList<Role>> GetRolesAsync(CancellationToken ct = default)
        => await _db.Set<Role>().AsNoTracking().OrderBy(r => r.Name).ToListAsync(ct);

    public async Task<Role> CreateRoleAsync(RoleRequest req, CancellationToken ct = default)
    {
        if (await _db.Set<Role>().AnyAsync(r => r.Name == req.Name, ct))
            throw new ConflictAppException("Role name already exists");
        var role = new Role { Id = Guid.NewGuid(), Name = req.Name, Description = req.Description, IsSystem = false };
        _db.Set<Role>().Add(role);
        await _db.SaveChangesAsync(ct);
        return role;
    }

    public async Task<Role> UpdateRoleAsync(Guid id, RoleRequest req, CancellationToken ct = default)
    {
        var role = await GetRoleAsync(id, ct);
        if (role.IsSystem) throw new ForbiddenAppException("System roles cannot be modified");
        role.Name = req.Name;
        role.Description = req.Description;
        role.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        return role;
    }

    public async Task DeleteRoleAsync(Guid id, CancellationToken ct = default)
    {
        var role = await GetRoleAsync(id, ct);
        if (role.IsSystem) throw new ForbiddenAppException("System roles cannot be deleted");
        _db.Set<Role>().Remove(role);
        await _db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<Permission>> GetPermissionsAsync(CancellationToken ct = default)
        => await _db.Set<Permission>().AsNoTracking().OrderBy(p => p.Code).ToListAsync(ct);

    public async Task SetRolePermissionsAsync(Guid roleId, IEnumerable<Guid> permissionIds, CancellationToken ct = default)
    {
        var role = await GetRoleAsync(roleId, ct);
        if (role.IsSystem) throw new ForbiddenAppException("System role permissions are locked");

        var existing = await _db.Set<RolePermission>().Where(rp => rp.RoleId == roleId).ToListAsync(ct);
        _db.Set<RolePermission>().RemoveRange(existing);
        foreach (var pid in permissionIds.Distinct())
            _db.Set<RolePermission>().Add(new RolePermission { Id = Guid.NewGuid(), RoleId = roleId, PermissionId = pid });
        await _db.SaveChangesAsync(ct);

        await InvalidateRoleUsersAsync(roleId, ct);
    }

    public async Task AssignRoleAsync(Guid userId, Guid roleId, Guid assignedBy, CancellationToken ct = default)
    {
        if (!await _db.Set<UserRole>().AnyAsync(ur => ur.UserId == userId && ur.RoleId == roleId, ct))
        {
            _db.Set<UserRole>().Add(new UserRole
            {
                Id = Guid.NewGuid(), UserId = userId, RoleId = roleId, AssignedBy = assignedBy,
                AssignedAt = DateTimeOffset.UtcNow,
            });
            await _db.SaveChangesAsync(ct);
        }
        await _permissions.InvalidateAsync(userId, ct);
    }

    public async Task RemoveRoleAsync(Guid userId, Guid roleId, CancellationToken ct = default)
    {
        var link = await _db.Set<UserRole>().FirstOrDefaultAsync(ur => ur.UserId == userId && ur.RoleId == roleId, ct);
        if (link is not null)
        {
            _db.Set<UserRole>().Remove(link);
            await _db.SaveChangesAsync(ct);
        }
        await _permissions.InvalidateAsync(userId, ct);
    }

    public async Task<IReadOnlyList<SecurityEvent>> GetSecurityEventsAsync(CancellationToken ct = default)
        => await _db.Set<SecurityEvent>().AsNoTracking()
            .OrderByDescending(e => e.CreatedAt).Take(200).ToListAsync(ct);

    public async Task ResolveSecurityEventAsync(Guid id, Guid resolvedBy, CancellationToken ct = default)
    {
        var ev = await _db.Set<SecurityEvent>().FirstOrDefaultAsync(e => e.Id == id, ct)
            ?? throw new NotFoundAppException();
        ev.Resolved = true;
        ev.ResolvedBy = resolvedBy;
        ev.ResolvedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
    }

    private async Task<Role> GetRoleAsync(Guid id, CancellationToken ct)
        => await _db.Set<Role>().FirstOrDefaultAsync(r => r.Id == id, ct) ?? throw new NotFoundAppException();

    private async Task InvalidateRoleUsersAsync(Guid roleId, CancellationToken ct)
    {
        var userIds = await _db.Set<UserRole>().Where(ur => ur.RoleId == roleId)
            .Select(ur => ur.UserId).ToListAsync(ct);
        foreach (var uid in userIds) await _permissions.InvalidateAsync(uid, ct);
    }
}
