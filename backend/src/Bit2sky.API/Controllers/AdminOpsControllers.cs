using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

// AI system-prompt management (Section 13) — gated per action.
[Route("api/v1/admin/ai-prompts")]
[Authorize]
public class AdminAiPromptController : ApiControllerBase
{
    private readonly IAdminAiPromptService _prompts;
    public AdminAiPromptController(IAdminAiPromptService prompts) => _prompts = prompts;

    [HttpGet, RequirePermission("ai_prompts.view")]
    public async Task<IActionResult> List(CancellationToken ct) => Ok(await _prompts.ListAsync(ct));

    [HttpPost, RequirePermission("ai_prompts.create")]
    public async Task<IActionResult> Create([FromBody] AiPromptInput body, CancellationToken ct)
        => Ok(await _prompts.CreateAsync(body, RequireUserId(), ct), "Prompt created");

    [HttpPut("{id:guid}"), RequirePermission("ai_prompts.create")]
    public async Task<IActionResult> Update(Guid id, [FromBody] AiPromptInput body, CancellationToken ct)
        => Ok(await _prompts.UpdateAsync(id, body, ct), "Prompt updated");

    [HttpPut("{id:guid}/activate"), RequirePermission("ai_prompts.activate")]
    public async Task<IActionResult> Activate(Guid id, CancellationToken ct)
    { await _prompts.ActivateAsync(id, ct); return Ok<object?>(null, "Prompt activated"); }
}

// Notification broadcast + recent feed (Section 11/12) — gated per action.
[Route("api/v1/admin/notifications")]
[Authorize]
public class AdminNotificationController : ApiControllerBase
{
    private readonly INotificationService _notifications;
    public AdminNotificationController(INotificationService notifications) => _notifications = notifications;

    [HttpGet("recent"), RequirePermission("notifications.view")]
    public async Task<IActionResult> Recent([FromQuery] int take = 50, CancellationToken ct = default)
        => Ok(await _notifications.RecentAsync(take, ct));

    [HttpPost("broadcast"), RequirePermission("notifications.broadcast")]
    public async Task<IActionResult> Broadcast([FromBody] BroadcastDto body, CancellationToken ct)
    {
        var count = await _notifications.BroadcastAsync(body.Title, body.Body, body.DeepLink, ct);
        return Ok(new { recipients = count }, $"Sent to {count} user(s)");
    }
}

public record BroadcastDto(string Title, string Body, string? DeepLink);

// Admin support queue (Section 11) — view all, reply, close; gated per action.
[Route("api/v1/admin/support/tickets")]
[Authorize]
public class AdminSupportController : ApiControllerBase
{
    private readonly IAdminSupportService _support;
    public AdminSupportController(IAdminSupportService support) => _support = support;

    [HttpGet, RequirePermission("support.view")]
    public async Task<IActionResult> List([FromQuery] string? status, CancellationToken ct)
        => Ok(await _support.ListAsync(status, ct));

    [HttpGet("{id:guid}/messages"), RequirePermission("support.view")]
    public async Task<IActionResult> Messages(Guid id, CancellationToken ct)
        => Ok(await _support.GetMessagesAsync(id, ct));

    [HttpPost("{id:guid}/reply"), RequirePermission("support.respond")]
    public async Task<IActionResult> Reply(Guid id, [FromBody] TicketReplyDto body, CancellationToken ct)
        => Ok(await _support.ReplyAsync(id, RequireUserId(), body.Body, ct), "Reply sent");

    [HttpPut("{id:guid}/close"), RequirePermission("support.close")]
    public async Task<IActionResult> Close(Guid id, CancellationToken ct)
    { await _support.CloseAsync(id, ct); return Ok<object?>(null, "Ticket closed"); }
}

public record TicketReplyDto(string Body);

// Business analytics summary for the Reports dashboard (Section 11).
[Route("api/v1/admin/analytics")]
[Authorize]
public class AdminAnalyticsController : ApiControllerBase
{
    private readonly IAnalyticsService _analytics;
    public AdminAnalyticsController(IAnalyticsService analytics) => _analytics = analytics;

    [HttpGet("summary"), RequirePermission("analytics.view")]
    public async Task<IActionResult> Summary(CancellationToken ct) => Ok(await _analytics.GetSummaryAsync(ct));
}
