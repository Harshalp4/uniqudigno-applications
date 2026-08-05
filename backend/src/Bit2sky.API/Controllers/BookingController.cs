using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/bookings")]
[Authorize]
public class BookingController : ApiControllerBase
{
    private readonly IBookingService _bookings;

    public BookingController(IBookingService bookings) => _bookings = bookings;

    private (Guid userId, string role) Ctx() => (RequireUserId(), CurrentUser.Role ?? "customer");

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBookingRequest req, CancellationToken ct)
        => Ok(await _bookings.CreateAsync(RequireUserId(), req, ct), "Booking created");

    [HttpPost("{id:guid}/confirm")]
    public async Task<IActionResult> Confirm(Guid id, [FromBody] ConfirmBookingRequest req, CancellationToken ct)
    {
        await _bookings.ConfirmAsync(RequireUserId(), id, req, ct);
        return Ok<object?>(null, "Payment confirmed");
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct)
    {
        var (userId, role) = Ctx();
        return Ok(await _bookings.GetAsync(userId, role, null, id, ct));
    }

    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        var (userId, role) = Ctx();
        return Ok(await _bookings.ListAsync(userId, role, null, ct));
    }

    [HttpPut("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, [FromBody] CancelDto body, CancellationToken ct)
    {
        await _bookings.CancelAsync(RequireUserId(), id, body.Reason, ct);
        return Ok<object?>(null, "Booking cancelled");
    }

    [HttpPost("{id:guid}/reschedule")]
    public async Task<IActionResult> Reschedule(Guid id, [FromBody] RescheduleBookingRequest req, CancellationToken ct)
        => Ok(await _bookings.RescheduleAsync(RequireUserId(), id, req, ct), "Booking rescheduled");
}

public record CancelDto(string? Reason);

// Admin bookings grid (Section 11) — paged, optional status filter.
[Route("api/v1/admin/bookings")]
[Authorize]
public class AdminBookingController : ApiControllerBase
{
    private readonly IBookingService _bookings;

    public AdminBookingController(IBookingService bookings) => _bookings = bookings;

    [HttpGet]
    [RequirePermission("bookings.view")]
    public async Task<IActionResult> List([FromQuery] string? status, [FromQuery] PageRequest page, CancellationToken ct)
    {
        BookingStatus? parsed = Enum.TryParse<BookingStatus>(status, ignoreCase: true, out var s) ? s : null;
        var result = await _bookings.AdminListAsync(parsed, page, ct);
        return Ok(result.Items, "OK", new PaginationMeta { Page = result.Page, PageSize = result.PageSize, Total = result.Total });
    }

    [HttpPut("{id:guid}/assign-technician")]
    [RequirePermission("bookings.assign_technician")]
    public async Task<IActionResult> AssignTechnician(Guid id, [FromBody] AssignTechnicianDto body, CancellationToken ct)
    {
        await _bookings.AssignTechnicianAsync(id, body.TechnicianId, ct);
        return Ok<object?>(null, "Technician assigned");
    }
}

public record AssignTechnicianDto(Guid TechnicianId);
