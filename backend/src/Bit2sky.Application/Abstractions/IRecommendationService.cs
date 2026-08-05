using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

// Personalised "Recommended for You" tests (Section 7). Rule-based v1: profile
// (age/gender) + booking history, with a popularity default for guests/no-signal.
public interface IRecommendationService
{
    Task<IReadOnlyList<Test>> GetRecommendedTestsAsync(
        Guid? userId, int take = 6, CancellationToken ct = default);
}
