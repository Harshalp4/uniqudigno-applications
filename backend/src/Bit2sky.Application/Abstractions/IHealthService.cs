using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;

namespace Bit2sky.Application.Abstractions;

public record VitalRequest(VitalType Type, string Value, string? Unit, VitalSource Source);
public record LifestyleLogRequest(DateOnly LogDate, string Category, string? Value);
public record StepsRequest(DateOnly Date, int Steps, VitalSource Source);
public record SymptomCheckRequest(string SymptomsJson);

public interface IHealthService
{
    Task<HealthScore?> GetScoreAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<HealthScore>> GetScoreHistoryAsync(Guid userId, CancellationToken ct = default);
    Task<Vital> AddVitalAsync(Guid userId, VitalRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<Vital>> GetVitalsAsync(Guid userId, VitalType type, CancellationToken ct = default);
    Task DeleteVitalAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<StepEntry> AddStepsAsync(Guid userId, StepsRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<StepEntry>> GetStepsAsync(Guid userId, CancellationToken ct = default);
    Task<LifestyleLog> LogLifestyleAsync(Guid userId, LifestyleLogRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<Reminder>> GetRemindersAsync(Guid userId, CancellationToken ct = default);
    Task DismissReminderAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<SymptomCheck> SymptomCheckAsync(Guid? userId, SymptomCheckRequest req, CancellationToken ct = default);
}
