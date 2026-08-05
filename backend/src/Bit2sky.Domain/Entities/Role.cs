namespace Bit2sky.Domain.Entities;

// admin.roles (Section 6 — fully specified in v3).
public class Role
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;     // UNIQUE
    public string? Description { get; set; }
    public bool IsSystem { get; set; }            // system roles cannot be deleted
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
