using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Bit2sky.Application.Abstractions;

namespace Bit2sky.Application.Services;

// Rule-based recommender (v1). Scores the active catalogue for one user from
// explainable signals; with no user or no signals it degrades to a popularity
// ranking, so the section is NEVER empty (the "default" the product needs).
public class RecommendationService : IRecommendationService
{
    private readonly IAppDbContext _db;

    public RecommendationService(IAppDbContext db) => _db = db;

    // Keyword groups matched against a test's name + concern/risk tags.
    private static readonly string[] AgeOver40 =
        { "lipid", "hba1c", "diabet", "sugar", "cardiac", "heart", "cholesterol",
          "kidney", "kft", "liver", "lft", "full body", "vitamin b12" };
    private static readonly string[] Female =
        { "thyroid", "tsh", "iron", "ferritin", "vitamin d", "calcium",
          "haemoglobin", "hemoglobin", "women", "cbc" };
    private static readonly string[] Male =
        { "lipid", "cardiac", "liver", "psa", "prostate", "vitamin d" };

    public async Task<IReadOnlyList<Test>> GetRecommendedTestsAsync(
        Guid? userId, int take = 6, CancellationToken ct = default)
    {
        var tests = await _db.Set<Test>().AsNoTracking()
            .Where(t => t.IsActive).ToListAsync(ct);
        if (tests.Count == 0) return tests;

        int? age = null;
        Gender? gender = null;
        var recentTestIds = new HashSet<Guid>();

        if (userId is { } uid)
        {
            var user = await _db.Set<User>().AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == uid, ct);
            if (user is not null)
            {
                gender = user.Gender;
                if (user.DateOfBirth is { } dob)
                {
                    var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
                    age = today.Year - dob.Year - (dob > today.AddYears(-(today.Year - dob.Year)) ? 1 : 0);
                }
            }

            // Tests booked in the last 90 days — don't re-recommend the same ones.
            var since = DateTimeOffset.UtcNow.AddDays(-90);
            recentTestIds = (await (
                    from bi in _db.Set<BookingItem>().AsNoTracking()
                    join b in _db.Set<Booking>().AsNoTracking() on bi.BookingId equals b.Id
                    where b.UserId == uid && b.CreatedAt >= since && bi.TestId != null
                    select bi.TestId!.Value).Distinct().ToListAsync(ct))
                .ToHashSet();
        }

        var ranked = tests
            .Select(t => (test: t, score: Score(t, age, gender, recentTestIds)))
            .OrderByDescending(x => x.score)
            .ThenByDescending(x => x.test.RatingCount)
            .Select(x => x.test)
            .Take(take)
            .ToList();

        return ranked;
    }

    private static double Score(Test t, int? age, Gender? gender, HashSet<Guid> recent)
    {
        // Popularity baseline — this alone is the "default" ranking for guests.
        double score = (t.IsPopular ? 100 : 0)
            + Math.Min(t.RatingCount, 500) * 0.05
            + t.RatingAverage * 2;

        var haystack = $"{t.Name} {t.ConcernTags} {t.RiskTags}".ToLowerInvariant();

        if (age is >= 40 && AgeOver40.Any(haystack.Contains)) score += 40;
        if (gender == Gender.Female && Female.Any(haystack.Contains)) score += 40;
        if (gender == Gender.Male && Male.Any(haystack.Contains)) score += 25;

        // Recently booked → push far down (still returned only if nothing else).
        if (recent.Contains(t.Id)) score -= 1000;

        return score;
    }
}
