using Microsoft.AspNetCore.Authorization;

namespace Bit2sky.Application.Authorization;

// Scaffold placeholder. Declarative permission gate, e.g. [RequirePermission("booking.create")].
public class RequirePermissionAttribute : AuthorizeAttribute
{
    public const string PolicyPrefix = "PERMISSION_";

    public RequirePermissionAttribute(string permission)
    {
        Permission = permission;
    }

    public string Permission
    {
        get => Policy?[PolicyPrefix.Length..] ?? string.Empty;
        set => Policy = $"{PolicyPrefix}{value}";
    }
}
