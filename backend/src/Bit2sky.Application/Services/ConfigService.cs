using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Reads all config/layout from DB (ZERO HARDCODING — Section 5). Cached per spec TTLs.
public class ConfigService : IConfigService
{
    private readonly IAppDbContext _db;
    private readonly ICacheService _cache;

    public ConfigService(IAppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<IReadOnlyDictionary<string, string?>> GetPublicConfigAsync(string? category, CancellationToken ct = default)
    {
        var query = _db.Set<AppConfig>().Where(c => c.IsPublic);
        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(c => c.Category == category);
        return await query.ToDictionaryAsync(c => c.Key, c => c.Value, ct);
    }

    public async Task<IReadOnlyList<AppConfig>> GetAllConfigAsync(string? category, CancellationToken ct = default)
    {
        var query = _db.Set<AppConfig>().AsNoTracking();
        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(c => c.Category == category);
        return await query.OrderBy(c => c.Category).ThenBy(c => c.Key).ToListAsync(ct);
    }

    public async Task<IReadOnlyList<HomeSection>> GetHomeLayoutAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        return await _db.Set<HomeSection>()
            .Where(s => s.IsVisible
                && (s.ValidFrom == null || s.ValidFrom <= now)
                && (s.ValidUntil == null || s.ValidUntil >= now))
            .OrderBy(s => s.SortOrder)
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<HomeSection>> GetAllHomeSectionsAsync(CancellationToken ct = default)
        => await _db.Set<HomeSection>().OrderBy(s => s.SortOrder).ToListAsync(ct);

    public async Task UpdateHomeSectionAsync(Guid id, bool? isVisible, int? sortOrder, string? title, string? configJson, Guid adminId, CancellationToken ct = default)
    {
        var section = await _db.Set<HomeSection>().FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new NotFoundAppException();
        if (isVisible is { } v) section.IsVisible = v;
        if (sortOrder is { } o) section.SortOrder = o;
        if (title is not null) section.Title = title;
        if (configJson is not null) section.ConfigJson = configJson.Length == 0 ? null : configJson;
        section.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        await _cache.RemoveAsync("config:home_layout", ct);
    }

    public async Task<IReadOnlyList<QuickAction>> GetQuickActionsAsync(CancellationToken ct = default)
        => await _db.Set<QuickAction>().Where(q => q.IsVisible).OrderBy(q => q.SortOrder).ToListAsync(ct);

    public async Task<IReadOnlyList<NavItem>> GetNavItemsAsync(CancellationToken ct = default)
        => await _db.Set<NavItem>().Where(n => n.IsVisible).OrderBy(n => n.SortOrder).ToListAsync(ct);

    public async Task<IReadOnlyList<OnboardingSlide>> GetOnboardingSlidesAsync(CancellationToken ct = default)
        => await _db.Set<OnboardingSlide>().Where(o => o.IsActive).OrderBy(o => o.SortOrder).ToListAsync(ct);

    public async Task UpdateConfigAsync(string key, string? value, Guid adminId, CancellationToken ct = default)
    {
        var config = await _db.Set<AppConfig>().FirstOrDefaultAsync(c => c.Key == key, ct);
        if (config is null)
        {
            config = new AppConfig { Id = Guid.NewGuid(), Key = key };
            _db.Set<AppConfig>().Add(config);
        }
        config.Value = value;
        config.UpdatedAt = DateTimeOffset.UtcNow;
        config.UpdatedBy = adminId;
        await _db.SaveChangesAsync(ct);
        await _cache.RemoveAsync($"config:{key}", ct);
    }
}
