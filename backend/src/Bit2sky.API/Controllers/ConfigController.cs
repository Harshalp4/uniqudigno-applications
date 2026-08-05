using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1")]
public class ConfigController : ApiControllerBase
{
    private readonly IConfigService _config;

    public ConfigController(IConfigService config) => _config = config;

    [HttpGet("config/branding"), AllowAnonymous]
    public async Task<IActionResult> Branding(CancellationToken ct)
        => Ok(await _config.GetPublicConfigAsync("branding", ct));

    [HttpGet("config/features"), AllowAnonymous]
    public async Task<IActionResult> Features(CancellationToken ct)
        => Ok(await _config.GetPublicConfigAsync("feature", ct));

    [HttpGet("home/layout"), AllowAnonymous]
    public async Task<IActionResult> HomeLayout(CancellationToken ct)
        => Ok(await _config.GetHomeLayoutAsync(ct));

    [HttpGet("home/quick-actions"), AllowAnonymous]
    public async Task<IActionResult> QuickActions(CancellationToken ct)
        => Ok(await _config.GetQuickActionsAsync(ct));

    [HttpGet("nav/bottom"), AllowAnonymous]
    public async Task<IActionResult> Nav(CancellationToken ct)
        => Ok(await _config.GetNavItemsAsync(ct));

    [HttpGet("onboarding/slides"), AllowAnonymous]
    public async Task<IActionResult> Onboarding(CancellationToken ct)
        => Ok(await _config.GetOnboardingSlidesAsync(ct));

    [HttpGet("admin/config")]
    [RequirePermission("config.view")]
    public async Task<IActionResult> AdminConfig([FromQuery] string? category, CancellationToken ct)
        => Ok(await _config.GetAllConfigAsync(category, ct));

    [HttpPut("admin/config/{key}")]
    [RequirePermission("config.update")]
    public async Task<IActionResult> UpdateConfig(string key, [FromBody] ConfigValueDto body, CancellationToken ct)
    {
        await _config.UpdateConfigAsync(key, body.Value, RequireUserId(), ct);
        return Ok<object?>(null, "Config updated");
    }

    // ── Home-layout editor (Section 11) ──────────────────────────────────────
    [HttpGet("admin/home/sections")]
    [RequirePermission("home_layout.view")]
    public async Task<IActionResult> AdminHomeSections(CancellationToken ct)
        => Ok(await _config.GetAllHomeSectionsAsync(ct));

    [HttpPut("admin/home/sections/{id:guid}")]
    [RequirePermission("home_layout.update")]
    public async Task<IActionResult> UpdateHomeSection(Guid id, [FromBody] HomeSectionUpdateDto body, CancellationToken ct)
    {
        await _config.UpdateHomeSectionAsync(id, body.IsVisible, body.SortOrder, body.Title, body.ConfigJson, RequireUserId(), ct);
        return Ok<object?>(null, "Section updated");
    }
}

public record ConfigValueDto(string? Value);
// ConfigJson: null = leave unchanged, "" = clear, else replace payload.
public record HomeSectionUpdateDto(bool? IsVisible, int? SortOrder, string? Title = null, string? ConfigJson = null);
