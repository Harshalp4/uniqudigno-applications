using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

// Technician field app (Section 9). Any authenticated technician account; the
// service resolves the technician from the token and scopes to their own jobs.
[Route("api/v1/technician")]
[Authorize]
public class TechnicianController : ApiControllerBase
{
    private readonly ITechnicianService _tech;

    public TechnicianController(ITechnicianService tech) => _tech = tech;

    [HttpGet("bookings")]
    public async Task<IActionResult> Bookings(CancellationToken ct)
        => Ok(await _tech.TodaysBookingsAsync(RequireUserId(), ct));

    [HttpPut("bookings/{id:guid}/status")]
    public async Task<IActionResult> Advance(Guid id, [FromBody] AdvanceStatusRequest body, CancellationToken ct)
        => Ok(new { status = await _tech.AdvanceStatusAsync(RequireUserId(), id, body, ct) }, "Status updated");
}
