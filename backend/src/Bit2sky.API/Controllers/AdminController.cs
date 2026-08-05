using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/admin")]
[Authorize]
public class AdminController : ApiControllerBase
{
    private readonly IAdminRbacService _rbac;

    public AdminController(IAdminRbacService rbac) => _rbac = rbac;

    [HttpGet("roles"), RequirePermission("roles.view")]
    public async Task<IActionResult> Roles(CancellationToken ct) => Ok(await _rbac.GetRolesAsync(ct));

    [HttpPost("roles"), RequirePermission("roles.create")]
    public async Task<IActionResult> CreateRole([FromBody] RoleRequest req, CancellationToken ct) => Ok(await _rbac.CreateRoleAsync(req, ct), "Role created");

    [HttpPut("roles/{id:guid}"), RequirePermission("roles.update")]
    public async Task<IActionResult> UpdateRole(Guid id, [FromBody] RoleRequest req, CancellationToken ct) => Ok(await _rbac.UpdateRoleAsync(id, req, ct), "Role updated");

    [HttpDelete("roles/{id:guid}"), RequirePermission("roles.delete")] // super_admin only
    public async Task<IActionResult> DeleteRole(Guid id, CancellationToken ct) { await _rbac.DeleteRoleAsync(id, ct); return Ok<object?>(null, "Role deleted"); }

    [HttpGet("permissions"), RequirePermission("roles.view")]
    public async Task<IActionResult> Permissions(CancellationToken ct) => Ok(await _rbac.GetPermissionsAsync(ct));

    [HttpPut("roles/{id:guid}/permissions"), RequirePermission("roles.update")]
    public async Task<IActionResult> SetPermissions(Guid id, [FromBody] SetPermissionsDto body, CancellationToken ct)
    { await _rbac.SetRolePermissionsAsync(id, body.PermissionIds, ct); return Ok<object?>(null, "Permissions updated"); }

    [HttpPost("users/{id:guid}/roles"), RequirePermission("roles.update")]
    public async Task<IActionResult> AssignRole(Guid id, [FromBody] AssignRoleDto body, CancellationToken ct)
    { await _rbac.AssignRoleAsync(id, body.RoleId, RequireUserId(), ct); return Ok<object?>(null, "Role assigned"); }

    [HttpDelete("users/{id:guid}/roles/{roleId:guid}"), RequirePermission("roles.update")]
    public async Task<IActionResult> RemoveRole(Guid id, Guid roleId, CancellationToken ct)
    { await _rbac.RemoveRoleAsync(id, roleId, ct); return Ok<object?>(null, "Role removed"); }

    [HttpGet("security/events"), Authorize(Roles = "super_admin,admin")]
    public async Task<IActionResult> SecurityEvents(CancellationToken ct) => Ok(await _rbac.GetSecurityEventsAsync(ct));

    [HttpPut("security/events/{id:guid}/resolve"), Authorize(Roles = "super_admin,admin")]
    public async Task<IActionResult> Resolve(Guid id, CancellationToken ct)
    { await _rbac.ResolveSecurityEventAsync(id, RequireUserId(), ct); return Ok<object?>(null, "Resolved"); }
}

public record SetPermissionsDto(IEnumerable<Guid> PermissionIds);
public record AssignRoleDto(Guid RoleId);
