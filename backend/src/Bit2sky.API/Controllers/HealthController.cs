using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/health")]
[Authorize]
public class HealthController : ApiControllerBase
{
    private readonly IHealthService _health;

    public HealthController(IHealthService health) => _health = health;

    [HttpGet("score")] public async Task<IActionResult> Score(CancellationToken ct) => Ok(await _health.GetScoreAsync(RequireUserId(), ct));
    [HttpGet("score/history")] public async Task<IActionResult> History(CancellationToken ct) => Ok(await _health.GetScoreHistoryAsync(RequireUserId(), ct));

    [HttpPost("vitals")] public async Task<IActionResult> AddVital([FromBody] VitalRequest req, CancellationToken ct) => Ok(await _health.AddVitalAsync(RequireUserId(), req, ct), "Recorded");
    [HttpGet("vitals/{type}")] public async Task<IActionResult> Vitals(VitalType type, CancellationToken ct) => Ok(await _health.GetVitalsAsync(RequireUserId(), type, ct));
    [HttpDelete("vitals/{id:guid}")] public async Task<IActionResult> DeleteVital(Guid id, CancellationToken ct) { await _health.DeleteVitalAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Deleted"); }

    [HttpPost("steps")] public async Task<IActionResult> AddSteps([FromBody] StepsRequest req, CancellationToken ct) => Ok(await _health.AddStepsAsync(RequireUserId(), req, ct), "Recorded");
    [HttpGet("steps")] public async Task<IActionResult> Steps(CancellationToken ct) => Ok(await _health.GetStepsAsync(RequireUserId(), ct));

    [HttpPost("lifestyle-log")] public async Task<IActionResult> Lifestyle([FromBody] LifestyleLogRequest req, CancellationToken ct) => Ok(await _health.LogLifestyleAsync(RequireUserId(), req, ct), "Logged");

    [HttpGet("reminders")] public async Task<IActionResult> Reminders(CancellationToken ct) => Ok(await _health.GetRemindersAsync(RequireUserId(), ct));
    [HttpPost("reminders/{id:guid}/dismiss")] public async Task<IActionResult> Dismiss(Guid id, CancellationToken ct) { await _health.DismissReminderAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Dismissed"); }

    [HttpPost("symptom-check")]
    [AllowAnonymous]
    public async Task<IActionResult> Symptom([FromBody] SymptomCheckRequest req, CancellationToken ct)
        => Ok(await _health.SymptomCheckAsync(CurrentUser.UserId, req, ct));
}
