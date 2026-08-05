using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/ai")]
[Authorize]
public class AiController : ApiControllerBase
{
    private readonly IAiCopilotService _ai;

    public AiController(IAiCopilotService ai) => _ai = ai;

    [HttpGet("sessions")]
    public async Task<IActionResult> Sessions(CancellationToken ct) => Ok(await _ai.ListSessionsAsync(RequireUserId(), ct));

    [HttpPost("sessions")]
    public async Task<IActionResult> Create(CancellationToken ct) => Ok(await _ai.CreateSessionAsync(RequireUserId(), ct), "Session created");

    [HttpGet("sessions/{id:guid}/messages")]
    public async Task<IActionResult> Messages(Guid id, CancellationToken ct) => Ok(await _ai.GetMessagesAsync(RequireUserId(), id, ct));

    [HttpPost("sessions/{id:guid}/message")]
    public async Task<IActionResult> Send(Guid id, [FromBody] AiMessageDto body, CancellationToken ct)
        => Ok(await _ai.SendMessageAsync(RequireUserId(), id, body.Content, ct));

    [HttpDelete("sessions/{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await _ai.DeleteSessionAsync(RequireUserId(), id, ct);
        return Ok<object?>(null, "Session deleted");
    }
}

public record AiMessageDto(string Content);
