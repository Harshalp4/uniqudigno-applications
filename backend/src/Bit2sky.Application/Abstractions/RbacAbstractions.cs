namespace Bit2sky.Application.Abstractions;

public record UserPermissions(string Role, IReadOnlyCollection<string> Permissions, bool IsAdminPortalUser);

// Loads a user's role + permission codes (Section 3C). Cached in Redis (5-min TTL);
// invalidated on role/permission change.
public interface IPermissionService
{
    Task<UserPermissions> GetForUserAsync(Guid userId, CancellationToken ct = default);
    Task<bool> HasPermissionAsync(Guid userId, string permission, CancellationToken ct = default);
    Task InvalidateAsync(Guid userId, CancellationToken ct = default);
}

// Resource ownership verification — separate from permission checks (Section 4B IDOR).
public interface IOwnershipService
{
    Task<bool> CanAccessBookingAsync(Guid currentUserId, string role, Guid? partnerId, Guid bookingId, CancellationToken ct = default);
    Task<bool> CanAccessReportAsync(Guid currentUserId, Guid reportId, CancellationToken ct = default);
    // Generic: dependent rows that carry a UserId column.
    Task<bool> OwnsAsync<TEntity>(Guid currentUserId, Guid entityId, CancellationToken ct = default) where TEntity : class;
}
