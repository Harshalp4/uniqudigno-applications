using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Public content (Section 7). Article view-count incremented on slug fetch.
public class ContentService : IContentService
{
    private readonly IAppDbContext _db;
    public ContentService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<Banner>> GetBannersAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        return await _db.Set<Banner>().AsNoTracking()
            .Where(b => b.IsActive && (b.ValidFrom == null || b.ValidFrom <= now) && (b.ValidUntil == null || b.ValidUntil >= now))
            .OrderBy(b => b.SortOrder).ToListAsync(ct);
    }

    public async Task<IReadOnlyList<Article>> GetArticlesAsync(bool featuredOnly, string? lang = null, CancellationToken ct = default)
    {
        var query = _db.Set<Article>().AsNoTracking().Where(a => a.IsPublished);
        if (featuredOnly) query = query.Where(a => a.IsFeatured);
        if (!string.IsNullOrWhiteSpace(lang)) query = query.Where(a => a.Language == lang);
        return await query.OrderByDescending(a => a.CreatedAt).Take(100).ToListAsync(ct);
    }

    public async Task<Article> GetArticleBySlugAsync(string slug, CancellationToken ct = default)
    {
        var article = await _db.Set<Article>().FirstOrDefaultAsync(a => a.Slug == slug && a.IsPublished, ct)
            ?? throw new NotFoundAppException();
        article.ViewCount++;
        await _db.SaveChangesAsync(ct);
        return article;
    }
}
