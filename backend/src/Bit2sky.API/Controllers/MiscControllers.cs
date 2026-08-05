using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/notifications")]
[Authorize]
public class NotificationController : ApiControllerBase
{
    private readonly INotificationService _notifications;
    public NotificationController(INotificationService notifications) => _notifications = notifications;

    [HttpGet] public async Task<IActionResult> List(CancellationToken ct) => Ok(await _notifications.ListAsync(RequireUserId(), ct));
    [HttpGet("unread-count")] public async Task<IActionResult> Unread(CancellationToken ct) => Ok(new { count = await _notifications.UnreadCountAsync(RequireUserId(), ct) });
    [HttpPut("{id:guid}/read")] public async Task<IActionResult> Read(Guid id, CancellationToken ct) { await _notifications.MarkReadAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Marked read"); }
    [HttpPut("read-all")] public async Task<IActionResult> ReadAll(CancellationToken ct) { await _notifications.MarkAllReadAsync(RequireUserId(), ct); return Ok<object?>(null, "All read"); }
}

[Route("api/v1/devices")]
[Authorize]
public class DeviceController : ApiControllerBase
{
    private readonly INotificationService _notifications;
    public DeviceController(INotificationService notifications) => _notifications = notifications;

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDeviceDto body, CancellationToken ct)
    { await _notifications.RegisterDeviceAsync(RequireUserId(), body.FcmToken, body.Platform, ct); return Ok<object?>(null, "Device registered"); }
}

[Route("api/v1/support")]
[Authorize]
public class SupportController : ApiControllerBase
{
    private readonly ISupportService _support;
    public SupportController(ISupportService support) => _support = support;

    [HttpPost("tickets")] public async Task<IActionResult> Create([FromBody] CreateTicketRequest req, CancellationToken ct) => Ok(await _support.CreateAsync(RequireUserId(), req, ct), "Ticket created");
    [HttpGet("tickets")] public async Task<IActionResult> List(CancellationToken ct) => Ok(await _support.ListAsync(RequireUserId(), ct));
    [HttpGet("tickets/{id:guid}/messages")] public async Task<IActionResult> Messages(Guid id, CancellationToken ct) => Ok(await _support.GetMessagesAsync(RequireUserId(), id, ct));
    [HttpPost("tickets/{id:guid}/messages")] public async Task<IActionResult> AddMessage(Guid id, [FromBody] MessageDto body, CancellationToken ct) => Ok(await _support.AddMessageAsync(RequireUserId(), id, body.Body, ct), "Sent");
    [HttpPut("tickets/{id:guid}/close")] public async Task<IActionResult> Close(Guid id, CancellationToken ct) { await _support.CloseAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Closed"); }
}

[Route("api/v1")]
[AllowAnonymous]
public class ContentController : ApiControllerBase
{
    private readonly IContentService _content;
    public ContentController(IContentService content) => _content = content;

    [HttpGet("banners")] public async Task<IActionResult> Banners(CancellationToken ct) => Ok(await _content.GetBannersAsync(ct));
    [HttpGet("articles")] public async Task<IActionResult> Articles([FromQuery] string? lang, CancellationToken ct) => Ok(await _content.GetArticlesAsync(false, lang, ct));
    [HttpGet("articles/featured")] public async Task<IActionResult> Featured([FromQuery] string? lang, CancellationToken ct) => Ok(await _content.GetArticlesAsync(true, lang, ct));
    [HttpGet("articles/{slug}")] public async Task<IActionResult> Article(string slug, CancellationToken ct) => Ok(await _content.GetArticleBySlugAsync(slug, ct));
}

[Route("api/v1/partner")]
[Authorize]
public class PartnerController : ApiControllerBase
{
    private readonly IPartnerService _partner;
    public PartnerController(IPartnerService partner) => _partner = partner;

    // partnerId resolved from the authenticated partner's profile; using user id as the
    // partner key for app-level partner users (Section 3B).
    [HttpGet("dashboard")] public async Task<IActionResult> Dashboard(CancellationToken ct) => Ok(await _partner.GetDashboardAsync(RequireUserId(), ct));
    [HttpGet("commissions")] public async Task<IActionResult> Commissions(CancellationToken ct) => Ok(await _partner.GetCommissionsAsync(RequireUserId(), ct));
}

public record RegisterDeviceDto(string FcmToken, DevicePlatform Platform);
public record MessageDto(string Body);
