using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// admin.permissions (Section 6 — fully specified in v3).
public class Permission
{
    public Guid Id { get; set; }
    public string Code { get; set; } = null!;   // e.g. "bookings.view" — UNIQUE
    public string Module { get; set; } = null!;  // e.g. "bookings"
    public PermissionAction Action { get; set; }
    public string Description { get; set; } = null!;
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
}
