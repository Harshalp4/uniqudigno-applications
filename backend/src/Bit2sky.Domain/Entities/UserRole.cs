namespace Bit2sky.Domain.Entities;

// admin.user_roles (Section 6 — join table, UNIQUE(user_id, role_id)).
public class UserRole
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid RoleId { get; set; }
    public Guid? AssignedBy { get; set; }   // references core.users(id)
    public DateTimeOffset AssignedAt { get; set; }

    public User User { get; set; } = null!;
    public Role Role { get; set; } = null!;
}
