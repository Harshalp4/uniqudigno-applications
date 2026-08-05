namespace Bit2sky.Domain.Entities;

// admin.role_permissions (Section 6 — join table, UNIQUE(role_id, permission_id)).
public class RolePermission
{
    public Guid Id { get; set; }
    public Guid RoleId { get; set; }
    public Guid PermissionId { get; set; }

    public Role Role { get; set; } = null!;
    public Permission Permission { get; set; } = null!;
}
