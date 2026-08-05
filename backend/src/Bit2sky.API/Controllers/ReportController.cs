using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/reports")]
[Authorize]
public class ReportController : ApiControllerBase
{
    private readonly IReportService _reports;

    public ReportController(IReportService reports) => _reports = reports;

    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct) => Ok(await _reports.ListAsync(RequireUserId(), ct));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct) => Ok(await _reports.GetAsync(RequireUserId(), id, ct));

    [HttpGet("{id:guid}/parameters")]
    public async Task<IActionResult> Parameters(Guid id, CancellationToken ct) => Ok(await _reports.GetParametersAsync(RequireUserId(), id, ct));

    [HttpGet("{id:guid}/download")]
    public async Task<IActionResult> Download(Guid id, CancellationToken ct)
        => Ok(new { url = await _reports.GetDownloadUrlAsync(RequireUserId(), id, ct) }, "Signed URL (15-min expiry)");

    [HttpPost("{id:guid}/request-counselling")]
    public async Task<IActionResult> RequestCounselling(Guid id, CancellationToken ct)
    {
        await _reports.RequestCounsellingAsync(RequireUserId(), id, ct);
        return Ok<object?>(null, "Counselling requested");
    }
}
