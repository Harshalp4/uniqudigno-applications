using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public interface IConfigService
{
    Task<IReadOnlyDictionary<string, string?>> GetPublicConfigAsync(string? category, CancellationToken ct = default);
    // Admin: ALL config rows (incl. non-public), optionally filtered by category.
    Task<IReadOnlyList<AppConfig>> GetAllConfigAsync(string? category, CancellationToken ct = default);
    Task<IReadOnlyList<HomeSection>> GetHomeLayoutAsync(CancellationToken ct = default);
    // Admin: ALL sections incl. hidden, in sort order.
    Task<IReadOnlyList<HomeSection>> GetAllHomeSectionsAsync(CancellationToken ct = default);
    Task UpdateHomeSectionAsync(Guid id, bool? isVisible, int? sortOrder, string? title, string? configJson, Guid adminId, CancellationToken ct = default);
    Task<IReadOnlyList<QuickAction>> GetQuickActionsAsync(CancellationToken ct = default);
    Task<IReadOnlyList<NavItem>> GetNavItemsAsync(CancellationToken ct = default);
    Task<IReadOnlyList<OnboardingSlide>> GetOnboardingSlidesAsync(CancellationToken ct = default);
    Task UpdateConfigAsync(string key, string? value, Guid adminId, CancellationToken ct = default);
}
