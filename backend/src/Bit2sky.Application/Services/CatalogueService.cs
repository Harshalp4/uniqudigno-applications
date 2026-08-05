using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Catalogue reads (Section 7). Active rows only; paginated and searchable.
public class CatalogueService : ICatalogueService
{
    private readonly IAppDbContext _db;

    public CatalogueService(IAppDbContext db) => _db = db;

    public async Task<PagedResult<Test>> GetTestsAsync(string? search, PageRequest page, CancellationToken ct = default)
    {
        var query = _db.Set<Test>().AsNoTracking().Where(t => t.IsActive);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            // Lab names are full of dots and spaces ("C.B.C.", "T3 T4 TSH") —
            // match with punctuation stripped on both sides so "cbc" finds
            // "C.B.C." and "t3t4" finds "T3 T4 TSH".
            var compact = s.Replace(".", "").Replace(" ", "");
            query = query.Where(t => t.Name.ToLower().Contains(s)
                || t.Name.ToLower().Replace(".", "").Replace(" ", "").Contains(compact)
                || (t.ShortDescription != null && t.ShortDescription.ToLower().Contains(s)));
        }
        var total = await query.CountAsync(ct);
        var items = await query.OrderBy(t => t.Name).Skip(page.Skip).Take(page.PageSize).ToListAsync(ct);
        return new PagedResult<Test> { Items = items, Total = total, Page = page.Page, PageSize = page.PageSize };
    }

    public async Task<Test> GetTestBySlugAsync(string slug, CancellationToken ct = default)
        => await _db.Set<Test>().AsNoTracking().FirstOrDefaultAsync(t => t.Slug == slug && t.IsActive, ct)
           ?? throw new NotFoundAppException();

    public async Task<IReadOnlyList<TestParameter>> GetTestParametersAsync(Guid testId, CancellationToken ct = default)
        => await _db.Set<TestParameter>().AsNoTracking().Where(p => p.TestId == testId)
            .OrderBy(p => p.SortOrder).ToListAsync(ct);

    public async Task<IReadOnlyList<Test>> GetPopularTestsAsync(CancellationToken ct = default)
        => await _db.Set<Test>().AsNoTracking().Where(t => t.IsActive && t.IsPopular)
            .OrderByDescending(t => t.RatingCount).Take(20).ToListAsync(ct);

    public async Task<PagedResult<Package>> GetPackagesAsync(PageRequest page, CancellationToken ct = default)
    {
        var query = _db.Set<Package>().AsNoTracking()
            .Include(p => p.PackageCategories).Where(p => p.IsActive);
        var total = await query.CountAsync(ct);
        var items = await query.OrderBy(p => p.Name).Skip(page.Skip).Take(page.PageSize).ToListAsync(ct);
        return new PagedResult<Package> { Items = items, Total = total, Page = page.Page, PageSize = page.PageSize };
    }

    public async Task<PackageDetailDto> GetPackageBySlugAsync(string slug, CancellationToken ct = default)
    {
        var pkg = await _db.Set<Package>().AsNoTracking()
            .Include(p => p.PackageCategories)
            .Include(p => p.PackageTests).ThenInclude(pt => pt.Test)
            .FirstOrDefaultAsync(p => p.Slug == slug && p.IsActive, ct)
            ?? throw new NotFoundAppException();

        var tests = pkg.PackageTests
            .Where(pt => pt.Test != null)
            .Select(pt => new PackageTestLine(pt.Test.Name, pt.Test.Slug, pt.Test.ParameterCount))
            .OrderByDescending(t => t.ParameterCount).ThenBy(t => t.Name)
            .ToList();

        return new PackageDetailDto(
            pkg.Id, pkg.Name, pkg.Slug, pkg.ShortDescription, pkg.Description,
            pkg.Mrp, pkg.Price, pkg.TestCount, pkg.ParameterCount,
            pkg.FastingRequired, pkg.ReportTimeText, pkg.IsPopular, pkg.IsFeatured,
            tests, pkg.PackageCategories.Select(pc => pc.CategoryId).ToList(),
            pkg.FastingHours, pkg.SampleType, pkg.Preparation, pkg.RecommendedFor,
            DeserializeFaqs(pkg.FaqJson));
    }

    // FAQs are stored as a JSON array on the package; empty/invalid → no FAQ
    // section (never surfaces a parse error to the app).
    private static IReadOnlyList<PackageFaq> DeserializeFaqs(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return Array.Empty<PackageFaq>();
        try
        {
            var faqs = System.Text.Json.JsonSerializer.Deserialize<List<PackageFaq>>(
                json, JsonOpts);
            return faqs?
                .Where(f => !string.IsNullOrWhiteSpace(f.Question)
                            && !string.IsNullOrWhiteSpace(f.Answer))
                .ToList() ?? (IReadOnlyList<PackageFaq>)Array.Empty<PackageFaq>();
        }
        catch { return Array.Empty<PackageFaq>(); }
    }

    private static string? SerializeFaqs(IReadOnlyList<PackageFaq>? faqs)
    {
        var clean = faqs?
            .Where(f => !string.IsNullOrWhiteSpace(f.Question)
                        && !string.IsNullOrWhiteSpace(f.Answer))
            .ToList();
        return clean is null || clean.Count == 0
            ? null
            : System.Text.Json.JsonSerializer.Serialize(clean, JsonOpts);
    }

    // camelCase so the stored FaqJson matches the rest of the API surface
    // (the admin form and app both read camelCase keys); case-insensitive read
    // still tolerates any legacy PascalCase rows.
    private static readonly System.Text.Json.JsonSerializerOptions JsonOpts =
        new()
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase,
        };

    public async Task<CategoryLandingDto> GetCategoryLandingAsync(string slug, CancellationToken ct = default)
    {
        var cat = await _db.Set<Category>().AsNoTracking()
            .FirstOrDefaultAsync(c => c.Slug == slug && c.IsActive, ct)
            ?? throw new NotFoundAppException();

        // Packages tagged to this category (active), popular first.
        var packages = await _db.Set<Package>().AsNoTracking()
            .Include(p => p.PackageCategories)
            .Include(p => p.PackageTests)
            .Where(p => p.IsActive && p.PackageCategories.Any(pc => pc.CategoryId == cat.Id))
            .OrderByDescending(p => p.IsPopular).ThenBy(p => p.Price)
            .ToListAsync(ct);

        // Individual tests tagged to this category (active), popular first.
        var tests = await _db.Set<Test>().AsNoTracking()
            .Include(t => t.TestCategories)
            .Where(t => t.IsActive && t.TestCategories.Any(tc => tc.CategoryId == cat.Id))
            .OrderByDescending(t => t.IsPopular).ThenBy(t => t.Price)
            .ToListAsync(ct);

        return new CategoryLandingDto(
            cat.Id, cat.Name, cat.Slug, cat.Type.ToString(), cat.IconUrl, packages, tests);
    }

    public async Task<IReadOnlyList<Category>> GetCategoriesAsync(string? type, CancellationToken ct = default)
    {
        var query = _db.Set<Category>().AsNoTracking().Where(c => c.IsActive);
        if (!string.IsNullOrWhiteSpace(type) && Enum.TryParse<Domain.Enums.CatalogueCategoryType>(type, true, out var t))
            query = query.Where(c => c.Type == t);
        return await query.OrderBy(c => c.SortOrder).ToListAsync(ct);
    }

    // ── Admin category master (the filter-chip config) ───────────────────────
    public async Task<IReadOnlyList<Category>> AdminListCategoriesAsync(string? type, CancellationToken ct = default)
    {
        var query = _db.Set<Category>().AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(type) && Enum.TryParse<Domain.Enums.CatalogueCategoryType>(type, true, out var t))
            query = query.Where(c => c.Type == t);
        return await query.OrderBy(c => c.SortOrder).ThenBy(c => c.Name).ToListAsync(ct);
    }

    public async Task<Category> AdminCreateCategoryAsync(CategoryInput input, CancellationToken ct = default)
    {
        var slug = Slugify(input.Slug, input.Name);
        if (await _db.Set<Category>().AnyAsync(c => c.Slug == slug, ct))
            throw new ConflictAppException("A category with this slug already exists.");
        var cat = new Category { Id = Guid.NewGuid(), Slug = slug };
        ApplyCategory(cat, input);
        _db.Set<Category>().Add(cat);
        await _db.SaveChangesAsync(ct);
        return cat;
    }

    public async Task<Category> AdminUpdateCategoryAsync(Guid id, CategoryInput input, CancellationToken ct = default)
    {
        var cat = await _db.Set<Category>().FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new NotFoundAppException();
        var slug = Slugify(input.Slug, input.Name);
        if (slug != cat.Slug && await _db.Set<Category>().AnyAsync(c => c.Slug == slug && c.Id != id, ct))
            throw new ConflictAppException("A category with this slug already exists.");
        cat.Slug = slug;
        ApplyCategory(cat, input);
        await _db.SaveChangesAsync(ct);
        return cat;
    }

    public async Task AdminSetCategoryActiveAsync(Guid id, bool active, CancellationToken ct = default)
    {
        var cat = await _db.Set<Category>().FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new NotFoundAppException();
        cat.IsActive = active;
        await _db.SaveChangesAsync(ct);
    }

    private static void ApplyCategory(Category c, CategoryInput i)
    {
        c.Name = i.Name.Trim();
        c.Type = Enum.TryParse<Domain.Enums.CatalogueCategoryType>(i.Type, true, out var t)
            ? t : Domain.Enums.CatalogueCategoryType.Package;
        c.IconUrl = i.IconUrl;
        c.ShowInFilter = i.ShowInFilter;
        c.SortOrder = i.SortOrder;
        c.IsActive = i.IsActive;
    }

    public async Task<IReadOnlyList<Specialty>> GetSpecialtiesAsync(CancellationToken ct = default)
        => await _db.Set<Specialty>().AsNoTracking().Where(s => s.IsActive).OrderBy(s => s.SortOrder).ToListAsync(ct);

    public async Task<IReadOnlyList<Centre>> GetCentresAsync(CancellationToken ct = default)
        => await _db.Set<Centre>().AsNoTracking().Where(c => c.IsActive).OrderBy(c => c.Name).ToListAsync(ct);

    public async Task<IReadOnlyList<Doctor>> GetDoctorsAsync(CancellationToken ct = default)
        => await _db.Set<Doctor>().AsNoTracking().Where(d => d.IsActive).OrderBy(d => d.Name).ToListAsync(ct);

    public async Task<IReadOnlyList<Supplement>> GetSupplementsAsync(CancellationToken ct = default)
        => await _db.Set<Supplement>().AsNoTracking().Where(s => s.IsActive).OrderBy(s => s.Name).ToListAsync(ct);

    // ── Admin test CRUD (Section 11). Admin list includes inactive rows. ──────
    public async Task<PagedResult<Test>> AdminListTestsAsync(string? search, PageRequest page, CancellationToken ct = default)
    {
        var query = _db.Set<Test>().AsNoTracking();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(t => t.Name.ToLower().Contains(s) || t.Slug.ToLower().Contains(s));
        }
        var total = await query.CountAsync(ct);
        var items = await query.Include(t => t.TestCategories)
            .OrderBy(t => t.Name).Skip(page.Skip).Take(page.PageSize).ToListAsync(ct);
        return new PagedResult<Test> { Items = items, Total = total, Page = page.Page, PageSize = page.PageSize };
    }

    public async Task<Test> AdminCreateTestAsync(TestInput input, CancellationToken ct = default)
    {
        var slug = Slugify(input.Slug, input.Name);
        if (await _db.Set<Test>().AnyAsync(t => t.Slug == slug, ct))
            throw new ConflictAppException("A test with this slug already exists.");

        var test = new Test { Id = Guid.NewGuid(), Slug = slug };
        Apply(test, input);
        SyncTestCategories(test, input.CategoryIds);
        _db.Set<Test>().Add(test);
        await _db.SaveChangesAsync(ct);
        return test;
    }

    public async Task<Test> AdminUpdateTestAsync(Guid id, TestInput input, CancellationToken ct = default)
    {
        var test = await _db.Set<Test>().Include(t => t.TestCategories)
            .FirstOrDefaultAsync(t => t.Id == id, ct)
            ?? throw new NotFoundAppException();

        var slug = Slugify(input.Slug, input.Name);
        if (slug != test.Slug && await _db.Set<Test>().AnyAsync(t => t.Slug == slug && t.Id != id, ct))
            throw new ConflictAppException("A test with this slug already exists.");

        test.Slug = slug;
        Apply(test, input);
        SyncTestCategories(test, input.CategoryIds);
        await _db.SaveChangesAsync(ct);
        return test;
    }

    // Sync a test's browse-category tags (diff-based; null = leave unchanged).
    // Composite-key join → no ValueGeneratedOnAdd Id trap.
    private static void SyncTestCategories(Test test, IReadOnlyList<Guid>? categoryIds)
    {
        if (categoryIds is null) return;
        var want = categoryIds.Distinct().ToHashSet();
        foreach (var stale in test.TestCategories.Where(tc => !want.Contains(tc.CategoryId)).ToList())
            test.TestCategories.Remove(stale);
        var have = test.TestCategories.Select(tc => tc.CategoryId).ToHashSet();
        foreach (var cid in want.Where(c => !have.Contains(c)))
            test.TestCategories.Add(new TestCategory { TestId = test.Id, CategoryId = cid });
    }

    public async Task AdminSetTestActiveAsync(Guid id, bool active, CancellationToken ct = default)
    {
        var test = await _db.Set<Test>().FirstOrDefaultAsync(t => t.Id == id, ct)
            ?? throw new NotFoundAppException();
        test.IsActive = active;
        await _db.SaveChangesAsync(ct);
    }

    private static void Apply(Test t, TestInput i)
    {
        t.Name = i.Name.Trim();
        t.ShortDescription = i.ShortDescription;
        t.Mrp = i.Mrp;
        t.Price = i.Price;
        t.SampleType = i.SampleType;
        t.FastingRequired = i.FastingRequired;
        t.HomeCollectionAvailable = i.HomeCollectionAvailable;
        t.IsPopular = i.IsPopular;
        t.IsActive = i.IsActive;
    }

    // ── Admin package CRUD (Section 11). Admin list includes inactive rows. ───
    public async Task<PagedResult<Package>> AdminListPackagesAsync(string? search, PageRequest page, CancellationToken ct = default)
    {
        var query = _db.Set<Package>().AsNoTracking()
            .Include(p => p.PackageCategories)
            .Include(p => p.PackageTests)
            .AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.Name.ToLower().Contains(s) || p.Slug.ToLower().Contains(s));
        }
        var total = await query.CountAsync(ct);
        var items = await query.OrderBy(p => p.Name).Skip(page.Skip).Take(page.PageSize).ToListAsync(ct);
        return new PagedResult<Package> { Items = items, Total = total, Page = page.Page, PageSize = page.PageSize };
    }

    public async Task<Package> AdminCreatePackageAsync(PackageInput input, CancellationToken ct = default)
    {
        var slug = Slugify(input.Slug, input.Name);
        if (await _db.Set<Package>().AnyAsync(p => p.Slug == slug, ct))
            throw new ConflictAppException("A package with this slug already exists.");

        var pkg = new Package { Id = Guid.NewGuid(), Slug = slug };
        Apply(pkg, input);
        SyncCategories(pkg, input.CategoryIds);
        SyncTests(pkg, input.TestIds);
        _db.Set<Package>().Add(pkg);
        await _db.SaveChangesAsync(ct);
        return pkg;
    }

    public async Task<Package> AdminUpdatePackageAsync(Guid id, PackageInput input, CancellationToken ct = default)
    {
        var pkg = await _db.Set<Package>()
            .Include(p => p.PackageCategories)
            .Include(p => p.PackageTests)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundAppException();

        var slug = Slugify(input.Slug, input.Name);
        if (slug != pkg.Slug && await _db.Set<Package>().AnyAsync(p => p.Slug == slug && p.Id != id, ct))
            throw new ConflictAppException("A package with this slug already exists.");

        pkg.Slug = slug;
        Apply(pkg, input);
        SyncCategories(pkg, input.CategoryIds);
        SyncTests(pkg, input.TestIds);
        await _db.SaveChangesAsync(ct);
        return pkg;
    }

    // Sync the package's category set to the requested ids (null = leave as-is).
    // Diffs rather than clear-and-re-add so unchanged rows aren't deleted +
    // re-inserted (which trips EF's optimistic-concurrency check).
    private static void SyncCategories(Package pkg, IReadOnlyList<Guid>? categoryIds)
    {
        if (categoryIds is null) return;
        var want = categoryIds.Distinct().ToHashSet();
        foreach (var stale in pkg.PackageCategories.Where(pc => !want.Contains(pc.CategoryId)).ToList())
            pkg.PackageCategories.Remove(stale);
        var have = pkg.PackageCategories.Select(pc => pc.CategoryId).ToHashSet();
        foreach (var cid in want.Where(c => !have.Contains(c)))
            pkg.PackageCategories.Add(new PackageCategory { PackageId = pkg.Id, CategoryId = cid });
    }

    // Sync the package's included-test set to the requested ids (diff-based).
    private static void SyncTests(Package pkg, IReadOnlyList<Guid>? testIds)
    {
        if (testIds is null) return;
        var want = testIds.Distinct().ToHashSet();
        foreach (var stale in pkg.PackageTests.Where(pt => !want.Contains(pt.TestId)).ToList())
            pkg.PackageTests.Remove(stale);
        var have = pkg.PackageTests.Select(pt => pt.TestId).ToHashSet();
        foreach (var tid in want.Where(t => !have.Contains(t)))
            // Leave Id unset: it's ValueGeneratedOnAdd, so a manual (non-default)
            // value trips EF's IsKeySet heuristic into treating the new row as an
            // existing one → UPDATE affecting 0 rows → optimistic-concurrency error.
            pkg.PackageTests.Add(new PackageTest { PackageId = pkg.Id, TestId = tid });
    }

    public async Task AdminSetPackageActiveAsync(Guid id, bool active, CancellationToken ct = default)
    {
        var pkg = await _db.Set<Package>().FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundAppException();
        pkg.IsActive = active;
        await _db.SaveChangesAsync(ct);
    }

    private static void Apply(Package p, PackageInput i)
    {
        p.Name = i.Name.Trim();
        p.ShortDescription = i.ShortDescription;
        p.Description = i.Description;
        p.Mrp = i.Mrp;
        p.Price = i.Price;
        p.TestCount = i.TestCount;
        p.ParameterCount = i.ParameterCount;
        p.FastingRequired = i.FastingRequired;
        p.ReportTimeText = i.ReportTimeText;
        p.FastingHours = i.FastingHours;
        p.SampleType = string.IsNullOrWhiteSpace(i.SampleType) ? null : i.SampleType.Trim();
        p.Preparation = string.IsNullOrWhiteSpace(i.Preparation) ? null : i.Preparation.Trim();
        p.RecommendedFor = string.IsNullOrWhiteSpace(i.RecommendedFor) ? null : i.RecommendedFor.Trim();
        p.FaqJson = SerializeFaqs(i.Faqs);
        p.IsPopular = i.IsPopular;
        p.IsFeatured = i.IsFeatured;
        p.IsActive = i.IsActive;
    }

    private static string Slugify(string? slug, string name)
    {
        var basis = string.IsNullOrWhiteSpace(slug) ? name : slug;
        var lowered = basis.Trim().ToLowerInvariant();
        var chars = lowered.Select(c => char.IsLetterOrDigit(c) ? c : '-').ToArray();
        var collapsed = new string(chars).Trim('-');
        while (collapsed.Contains("--")) collapsed = collapsed.Replace("--", "-");
        return collapsed.Length == 0 ? Guid.NewGuid().ToString("N")[..8] : collapsed;
    }
}
