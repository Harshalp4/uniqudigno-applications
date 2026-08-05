using Microsoft.AspNetCore.Authorization;

namespace Bit2sky.Application.Authorization;

// Scaffold placeholder. Carries the permission code an endpoint requires.
public class PermissionRequirement : IAuthorizationRequirement
{
    public string Permission { get; }

    public PermissionRequirement(string permission)
    {
        Permission = permission;
    }
}
