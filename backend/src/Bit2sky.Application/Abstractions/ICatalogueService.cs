using Bit2sky.Domain.Entities;
using Bit2sky.Shared;

namespace Bit2sky.Application.Abstractions;

// Admin create/edit payload for a diagnostic test (Section 11).
public record TestInput(
    string Name, string? Slug, string? ShortDescription, decimal Mrp, decimal Price,
    string? SampleType, bool FastingRequired, bool HomeCollectionAvailable,
    bool IsPopular, bool IsActive, IReadOnlyList<Guid>? CategoryIds = null);

// Admin create/edit payload for a health package (Section 11).
// CategoryIds assigns filter categories; TestIds assigns the included tests
// (both many-to-many; null = leave unchanged).
public record PackageInput(
    string Name, string? Slug, string? ShortDescription, string? Description,
    decimal Mrp, decimal Price, int TestCount, int ParameterCount,
    bool FastingRequired, string? ReportTimeText, bool IsPopular, bool IsFeatured, bool IsActive,
    IReadOnlyList<Guid>? CategoryIds = null, IReadOnlyList<Guid>? TestIds = null,
    int? FastingHours = null, string? SampleType = null, string? Preparation = null,
    string? RecommendedFor = null, IReadOnlyList<PackageFaq>? Faqs = null);

// One FAQ entry on a package-detail screen.
public record PackageFaq(string Question, string Answer);

// Admin create/edit payload for a catalogue category (the filter-chip master).
public record CategoryInput(
    string Name, string? Slug, string Type, string? IconUrl,
    bool ShowInFilter, int SortOrder, bool IsActive);

// One included test line on a package-detail screen.
public record PackageTestLine(string Name, string Slug, int ParameterCount);

// Package detail (the "Details >>" screen): meta + the tests bundled inside +
// the categories it's tagged with.
public record PackageDetailDto(
    Guid Id, string Name, string Slug, string? ShortDescription, string? Description,
    decimal Mrp, decimal Price, int TestCount, int ParameterCount,
    bool FastingRequired, string? ReportTimeText, bool IsPopular, bool IsFeatured,
    IReadOnlyList<PackageTestLine> IncludedTests, IReadOnlyList<Guid> CategoryIds,
    int? FastingHours, string? SampleType, string? Preparation, string? RecommendedFor,
    IReadOnlyList<PackageFaq> Faqs);

// A category landing page (tap Heart / Diabetes / Women's Care): the category
// itself plus the packages and individual tests tagged to it. Packages first.
public record CategoryLandingDto(
    Guid Id, string Name, string Slug, string Type, string? IconUrl,
    IReadOnlyList<Package> Packages, IReadOnlyList<Test> Tests);

public interface ICatalogueService
{
    // Category landing — everything tagged to one browse category, by slug.
    Task<CategoryLandingDto> GetCategoryLandingAsync(string slug, CancellationToken ct = default);
    Task<PagedResult<Test>> GetTestsAsync(string? search, PageRequest page, CancellationToken ct = default);
    Task<PagedResult<Test>> AdminListTestsAsync(string? search, PageRequest page, CancellationToken ct = default);
    Task<Test> AdminCreateTestAsync(TestInput input, CancellationToken ct = default);
    Task<Test> AdminUpdateTestAsync(Guid id, TestInput input, CancellationToken ct = default);
    Task AdminSetTestActiveAsync(Guid id, bool active, CancellationToken ct = default);
    Task<Test> GetTestBySlugAsync(string slug, CancellationToken ct = default);
    Task<IReadOnlyList<TestParameter>> GetTestParametersAsync(Guid testId, CancellationToken ct = default);
    Task<IReadOnlyList<Test>> GetPopularTestsAsync(CancellationToken ct = default);
    Task<PagedResult<Package>> GetPackagesAsync(PageRequest page, CancellationToken ct = default);
    Task<PackageDetailDto> GetPackageBySlugAsync(string slug, CancellationToken ct = default);
    Task<PagedResult<Package>> AdminListPackagesAsync(string? search, PageRequest page, CancellationToken ct = default);
    Task<Package> AdminCreatePackageAsync(PackageInput input, CancellationToken ct = default);
    Task<Package> AdminUpdatePackageAsync(Guid id, PackageInput input, CancellationToken ct = default);
    Task AdminSetPackageActiveAsync(Guid id, bool active, CancellationToken ct = default);
    Task<IReadOnlyList<Category>> GetCategoriesAsync(string? type, CancellationToken ct = default);
    // ── Admin category master (filter chips) ──
    Task<IReadOnlyList<Category>> AdminListCategoriesAsync(string? type, CancellationToken ct = default);
    Task<Category> AdminCreateCategoryAsync(CategoryInput input, CancellationToken ct = default);
    Task<Category> AdminUpdateCategoryAsync(Guid id, CategoryInput input, CancellationToken ct = default);
    Task AdminSetCategoryActiveAsync(Guid id, bool active, CancellationToken ct = default);
    Task<IReadOnlyList<Specialty>> GetSpecialtiesAsync(CancellationToken ct = default);
    Task<IReadOnlyList<Centre>> GetCentresAsync(CancellationToken ct = default);
    Task<IReadOnlyList<Doctor>> GetDoctorsAsync(CancellationToken ct = default);
    Task<IReadOnlyList<Supplement>> GetSupplementsAsync(CancellationToken ct = default);
}
