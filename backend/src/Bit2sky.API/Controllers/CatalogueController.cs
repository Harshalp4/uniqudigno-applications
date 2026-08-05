using Bit2sky.Application.Abstractions;
using Bit2sky.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1")]
[AllowAnonymous]
public class CatalogueController : ApiControllerBase
{
    private readonly ICatalogueService _catalogue;
    private readonly IRecommendationService _reco;
    private readonly ISlotService _slots;

    public CatalogueController(ICatalogueService catalogue, IRecommendationService reco, ISlotService slots)
    {
        _catalogue = catalogue;
        _reco = reco;
        _slots = slots;
    }

    [HttpGet("slots")]
    public async Task<IActionResult> Slots([FromQuery] DateOnly? date, [FromQuery] string? pincode, CancellationToken ct)
        => Ok(await _slots.GetAvailableAsync(date ?? DateOnly.FromDateTime(DateTime.UtcNow.Date).AddDays(1), pincode, ct));

    [HttpGet("tests")]
    public async Task<IActionResult> Tests([FromQuery] string? q, [FromQuery] PageRequest page, CancellationToken ct)
    {
        var result = await _catalogue.GetTestsAsync(q, page, ct);
        return Ok(result.Items, "OK", new PaginationMeta { Page = result.Page, PageSize = result.PageSize, Total = result.Total });
    }

    [HttpGet("tests/popular")]
    public async Task<IActionResult> Popular(CancellationToken ct) => Ok(await _catalogue.GetPopularTestsAsync(ct));

    // Personalised for the signed-in user; popularity default for guests (Section 7).
    [HttpGet("tests/recommended")]
    public async Task<IActionResult> Recommended([FromQuery] int take, CancellationToken ct)
        => Ok(await _reco.GetRecommendedTestsAsync(CurrentUser.UserId, take <= 0 ? 6 : take, ct));

    [HttpGet("tests/{slug}")]
    public async Task<IActionResult> Test(string slug, CancellationToken ct) => Ok(await _catalogue.GetTestBySlugAsync(slug, ct));

    [HttpGet("tests/{id:guid}/parameters")]
    public async Task<IActionResult> Parameters(Guid id, CancellationToken ct) => Ok(await _catalogue.GetTestParametersAsync(id, ct));

    [HttpGet("packages")]
    public async Task<IActionResult> Packages([FromQuery] PageRequest page, CancellationToken ct)
    {
        var result = await _catalogue.GetPackagesAsync(page, ct);
        return Ok(result.Items, "OK", new PaginationMeta { Page = result.Page, PageSize = result.PageSize, Total = result.Total });
    }

    [HttpGet("packages/{slug}")]
    public async Task<IActionResult> Package(string slug, CancellationToken ct) => Ok(await _catalogue.GetPackageBySlugAsync(slug, ct));

    [HttpGet("categories")]
    public async Task<IActionResult> Categories([FromQuery] string? type, CancellationToken ct) => Ok(await _catalogue.GetCategoriesAsync(type, ct));

    // Category landing (tap Heart / Diabetes / Women's Care): packages + tests
    // tagged to the category.
    [HttpGet("browse/{slug}")]
    public async Task<IActionResult> Browse(string slug, CancellationToken ct) => Ok(await _catalogue.GetCategoryLandingAsync(slug, ct));

    [HttpGet("specialties")]
    public async Task<IActionResult> Specialties(CancellationToken ct) => Ok(await _catalogue.GetSpecialtiesAsync(ct));

    [HttpGet("centres")]
    public async Task<IActionResult> Centres(CancellationToken ct) => Ok(await _catalogue.GetCentresAsync(ct));

    [HttpGet("doctors")]
    public async Task<IActionResult> Doctors(CancellationToken ct) => Ok(await _catalogue.GetDoctorsAsync(ct));

    [HttpGet("supplements")]
    public async Task<IActionResult> Supplements(CancellationToken ct) => Ok(await _catalogue.GetSupplementsAsync(ct));
}

// Admin catalogue management (Section 11) — gated per action; lists include inactive rows.
[Route("api/v1/admin/tests")]
[Authorize]
public class AdminCatalogueController : ApiControllerBase
{
    private readonly ICatalogueService _catalogue;

    public AdminCatalogueController(ICatalogueService catalogue) => _catalogue = catalogue;

    [HttpGet, Bit2sky.Application.Authorization.RequirePermission("tests.view")]
    public async Task<IActionResult> List([FromQuery] string? q, [FromQuery] PageRequest page, CancellationToken ct)
    {
        var result = await _catalogue.AdminListTestsAsync(q, page, ct);
        return Ok(result.Items, "OK", new PaginationMeta { Page = result.Page, PageSize = result.PageSize, Total = result.Total });
    }

    [HttpPost, Bit2sky.Application.Authorization.RequirePermission("tests.create")]
    public async Task<IActionResult> Create([FromBody] TestInput body, CancellationToken ct)
        => Ok(await _catalogue.AdminCreateTestAsync(body, ct), "Test created");

    [HttpPut("{id:guid}"), Bit2sky.Application.Authorization.RequirePermission("tests.update")]
    public async Task<IActionResult> Update(Guid id, [FromBody] TestInput body, CancellationToken ct)
        => Ok(await _catalogue.AdminUpdateTestAsync(id, body, ct), "Test updated");

    [HttpDelete("{id:guid}"), Bit2sky.Application.Authorization.RequirePermission("tests.delete")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
    { await _catalogue.AdminSetTestActiveAsync(id, false, ct); return Ok<object?>(null, "Test deactivated"); }
}

// Admin category master (filter-chip config) — gated per action.
[Route("api/v1/admin/categories")]
[Authorize]
public class AdminCategoryController : ApiControllerBase
{
    private readonly ICatalogueService _catalogue;

    public AdminCategoryController(ICatalogueService catalogue) => _catalogue = catalogue;

    [HttpGet, Bit2sky.Application.Authorization.RequirePermission("categories.view")]
    public async Task<IActionResult> List([FromQuery] string? type, CancellationToken ct)
        => Ok(await _catalogue.AdminListCategoriesAsync(type, ct));

    [HttpPost, Bit2sky.Application.Authorization.RequirePermission("categories.create")]
    public async Task<IActionResult> Create([FromBody] CategoryInput body, CancellationToken ct)
        => Ok(await _catalogue.AdminCreateCategoryAsync(body, ct), "Category created");

    [HttpPut("{id:guid}"), Bit2sky.Application.Authorization.RequirePermission("categories.update")]
    public async Task<IActionResult> Update(Guid id, [FromBody] CategoryInput body, CancellationToken ct)
        => Ok(await _catalogue.AdminUpdateCategoryAsync(id, body, ct), "Category updated");

    [HttpDelete("{id:guid}"), Bit2sky.Application.Authorization.RequirePermission("categories.delete")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
    { await _catalogue.AdminSetCategoryActiveAsync(id, false, ct); return Ok<object?>(null, "Category deactivated"); }
}

// Admin package management (Section 11) — gated per action; lists include inactive rows.
[Route("api/v1/admin/packages")]
[Authorize]
public class AdminPackageController : ApiControllerBase
{
    private readonly ICatalogueService _catalogue;

    public AdminPackageController(ICatalogueService catalogue) => _catalogue = catalogue;

    [HttpGet, Bit2sky.Application.Authorization.RequirePermission("packages.view")]
    public async Task<IActionResult> List([FromQuery] string? q, [FromQuery] PageRequest page, CancellationToken ct)
    {
        var result = await _catalogue.AdminListPackagesAsync(q, page, ct);
        return Ok(result.Items, "OK", new PaginationMeta { Page = result.Page, PageSize = result.PageSize, Total = result.Total });
    }

    [HttpPost, Bit2sky.Application.Authorization.RequirePermission("packages.create")]
    public async Task<IActionResult> Create([FromBody] PackageInput body, CancellationToken ct)
        => Ok(await _catalogue.AdminCreatePackageAsync(body, ct), "Package created");

    [HttpPut("{id:guid}"), Bit2sky.Application.Authorization.RequirePermission("packages.update")]
    public async Task<IActionResult> Update(Guid id, [FromBody] PackageInput body, CancellationToken ct)
        => Ok(await _catalogue.AdminUpdatePackageAsync(id, body, ct), "Package updated");

    [HttpDelete("{id:guid}"), Bit2sky.Application.Authorization.RequirePermission("packages.delete")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
    { await _catalogue.AdminSetPackageActiveAsync(id, false, ct); return Ok<object?>(null, "Package deactivated"); }
}
