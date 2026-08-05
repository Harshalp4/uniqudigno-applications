using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Bit2sky.Application.DTOs;
using Bit2sky.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/users/me")]
[Authorize]
public class UserController : ApiControllerBase
{
    private readonly IUserService _users;

    public UserController(IUserService users) => _users = users;

    [HttpGet] public async Task<IActionResult> Me(CancellationToken ct) => Ok(UserProfileDto.FromEntity(await _users.GetMeAsync(RequireUserId(), ct)));
    [HttpPut] public async Task<IActionResult> Update([FromBody] UpdateMeRequest req, CancellationToken ct) => Ok(UserProfileDto.FromEntity(await _users.UpdateMeAsync(RequireUserId(), req, ct)), "Updated");
    [HttpDelete] public async Task<IActionResult> Delete(CancellationToken ct) { await _users.SoftDeleteAsync(RequireUserId(), ct); return Ok<object?>(null, "Account deleted"); }
    [HttpGet("dashboard")] public async Task<IActionResult> Dashboard(CancellationToken ct) => Ok(await _users.GetDashboardAsync(RequireUserId(), ct));

    [HttpGet("family")] public async Task<IActionResult> Family(CancellationToken ct) => Ok(await _users.GetFamilyAsync(RequireUserId(), ct));
    [HttpPost("family")] public async Task<IActionResult> AddFamily([FromBody] FamilyMemberRequest req, CancellationToken ct) => Ok(await _users.AddFamilyAsync(RequireUserId(), req, ct), "Added");
    [HttpPut("family/{id:guid}")] public async Task<IActionResult> UpdateFamily(Guid id, [FromBody] FamilyMemberRequest req, CancellationToken ct) => Ok(await _users.UpdateFamilyAsync(RequireUserId(), id, req, ct), "Updated");
    [HttpDelete("family/{id:guid}")] public async Task<IActionResult> DeleteFamily(Guid id, CancellationToken ct) { await _users.DeleteFamilyAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Removed"); }

    [HttpGet("addresses")] public async Task<IActionResult> Addresses(CancellationToken ct) => Ok(await _users.GetAddressesAsync(RequireUserId(), ct));
    [HttpPost("addresses")] public async Task<IActionResult> AddAddress([FromBody] AddressRequest req, CancellationToken ct) => Ok(await _users.AddAddressAsync(RequireUserId(), req, ct), "Added");
    [HttpPut("addresses/{id:guid}")] public async Task<IActionResult> UpdateAddress(Guid id, [FromBody] AddressRequest req, CancellationToken ct) => Ok(await _users.UpdateAddressAsync(RequireUserId(), id, req, ct), "Updated");
    [HttpDelete("addresses/{id:guid}")] public async Task<IActionResult> DeleteAddress(Guid id, CancellationToken ct) { await _users.DeleteAddressAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Removed"); }
    [HttpPost("addresses/{id:guid}/set-default")] public async Task<IActionResult> SetDefault(Guid id, CancellationToken ct) { await _users.SetDefaultAddressAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Default set"); }
}

[Route("api/v1/admin/users")]
[Authorize]
public class AdminUserController : ApiControllerBase
{
    private readonly IUserService _users;

    public AdminUserController(IUserService users) => _users = users;

    [HttpGet]
    [RequirePermission("users.view")]
    public async Task<IActionResult> List([FromQuery] PageRequest page, CancellationToken ct)
    {
        var includePii = CurrentUser.HasPermission("users.view_pii");
        var result = await _users.AdminListAsync(includePii, page, ct);
        return Ok(result.Items, "OK", new PaginationMeta { Page = result.Page, PageSize = result.PageSize, Total = result.Total });
    }

    [HttpPut("{id:guid}/status")]
    [RequirePermission("users.update")]
    public async Task<IActionResult> SetStatus(Guid id, [FromBody] StatusDto body, CancellationToken ct)
    { await _users.DeactivateAsync(id, body.Active, ct); return Ok<object?>(null, "Status updated"); }

    [HttpDelete("{id:guid}")]
    [RequirePermission("users.delete")] // super_admin only (only super_admin holds this code)
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    { await _users.SoftDeleteAsync(id, ct); return Ok<object?>(null, "User soft-deleted"); }
}

public record StatusDto(bool Active);
