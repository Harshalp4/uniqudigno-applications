using System.Security.Claims;
using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.Authorization;

namespace Bit2sky.Application.Authorization;

// Section 3C #3: check "permission" claims in the JWT; fall back to a fresh DB check
// (handles permission changes mid-session).
public class PermissionAuthorizationHandler : AuthorizationHandler<PermissionRequirement>
{
    public const string PermissionClaimType = "permission";
    private readonly IPermissionService _permissionService;

    public PermissionAuthorizationHandler(IPermissionService permissionService)
        => _permissionService = permissionService;

    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context, PermissionRequirement requirement)
    {
        if (context.User.Identity?.IsAuthenticated != true) return;

        if (context.User.HasClaim(PermissionClaimType, requirement.Permission))
        {
            context.Succeed(requirement);
            return;
        }

        var sub = context.User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? context.User.FindFirstValue("sub");
        if (Guid.TryParse(sub, out var userId)
            && await _permissionService.HasPermissionAsync(userId, requirement.Permission))
        {
            context.Succeed(requirement);
        }
    }
}
