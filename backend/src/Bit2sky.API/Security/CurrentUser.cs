using System.Security.Claims;
using Bit2sky.Application.Abstractions;

namespace Bit2sky.API.Security;

// Ambient authenticated principal sourced from the validated JWT claims.
public class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor;

    public CurrentUser(IHttpContextAccessor accessor) => _accessor = accessor;

    public ClaimsPrincipal? Principal => _accessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated == true;

    public Guid? UserId
    {
        get
        {
            var sub = Principal?.FindFirstValue(ClaimTypes.NameIdentifier)
                      ?? Principal?.FindFirstValue("sub");
            return Guid.TryParse(sub, out var id) ? id : null;
        }
    }

    public string? Role => Principal?.FindFirstValue("role");

    public bool IsAdminPortalUser =>
        Role is "super_admin" or "admin" or "operations" or "finance" or "lab" or "content" or "support";

    public IReadOnlyCollection<string> Permissions =>
        Principal?.FindAll("permission").Select(c => c.Value).ToArray() ?? Array.Empty<string>();

    public bool HasPermission(string permission) => Permissions.Contains(permission);
}
