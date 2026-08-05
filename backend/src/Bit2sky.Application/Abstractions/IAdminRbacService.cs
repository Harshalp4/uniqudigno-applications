using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public record RoleRequest(string Name, string? Description);
public interface IAdminRbacService
{
    Task<IReadOnlyList<Role>> GetRolesAsync(CancellationToken ct = default);
    Task<Role> CreateRoleAsync(RoleRequest req, CancellationToken ct = default);
    Task<Role> UpdateRoleAsync(Guid id, RoleRequest req, CancellationToken ct = default);
    Task DeleteRoleAsync(Guid id, CancellationToken ct = default);                  // system roles protected
    Task<IReadOnlyList<Permission>> GetPermissionsAsync(CancellationToken ct = default);
    Task SetRolePermissionsAsync(Guid roleId, IEnumerable<Guid> permissionIds, CancellationToken ct = default);
    Task AssignRoleAsync(Guid userId, Guid roleId, Guid assignedBy, CancellationToken ct = default);
    Task RemoveRoleAsync(Guid userId, Guid roleId, CancellationToken ct = default);
    Task<IReadOnlyList<SecurityEvent>> GetSecurityEventsAsync(CancellationToken ct = default);
    Task ResolveSecurityEventAsync(Guid id, Guid resolvedBy, CancellationToken ct = default);
}
