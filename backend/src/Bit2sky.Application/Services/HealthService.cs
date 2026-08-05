using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Health score + trackers, own data only (Section 7). Score weights from config.
public class HealthService : IHealthService
{
    private readonly IAppDbContext _db;
    public HealthService(IAppDbContext db) => _db = db;

    public async Task<HealthScore?> GetScoreAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<HealthScore>().AsNoTracking().Where(h => h.UserId == userId)
            .OrderByDescending(h => h.CalculatedAt).FirstOrDefaultAsync(ct);

    public async Task<IReadOnlyList<HealthScore>> GetScoreHistoryAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<HealthScore>().AsNoTracking().Where(h => h.UserId == userId)
            .OrderByDescending(h => h.CalculatedAt).Take(50).ToListAsync(ct);

    public async Task<Vital> AddVitalAsync(Guid userId, VitalRequest req, CancellationToken ct = default)
    {
        var vital = new Vital { Id = Guid.NewGuid(), UserId = userId, Type = req.Type, Value = req.Value,
            Unit = req.Unit, Source = req.Source, RecordedAt = DateTimeOffset.UtcNow };
        _db.Set<Vital>().Add(vital);
        await _db.SaveChangesAsync(ct);
        return vital;
    }

    public async Task<IReadOnlyList<Vital>> GetVitalsAsync(Guid userId, VitalType type, CancellationToken ct = default)
        => await _db.Set<Vital>().AsNoTracking().Where(v => v.UserId == userId && v.Type == type)
            .OrderByDescending(v => v.RecordedAt).Take(100).ToListAsync(ct);

    public async Task DeleteVitalAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var vital = await _db.Set<Vital>().FirstOrDefaultAsync(v => v.Id == id && v.UserId == userId, ct)
            ?? throw new NotFoundAppException();
        _db.Set<Vital>().Remove(vital);
        await _db.SaveChangesAsync(ct);
    }

    public async Task<StepEntry> AddStepsAsync(Guid userId, StepsRequest req, CancellationToken ct = default)
    {
        var entry = await _db.Set<StepEntry>().FirstOrDefaultAsync(s => s.UserId == userId && s.Date == req.Date, ct);
        if (entry is null)
        {
            entry = new StepEntry { Id = Guid.NewGuid(), UserId = userId, Date = req.Date, Source = req.Source };
            _db.Set<StepEntry>().Add(entry);
        }
        entry.Steps = req.Steps;
        await _db.SaveChangesAsync(ct);
        return entry;
    }

    public async Task<IReadOnlyList<StepEntry>> GetStepsAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<StepEntry>().AsNoTracking().Where(s => s.UserId == userId)
            .OrderByDescending(s => s.Date).Take(90).ToListAsync(ct);

    public async Task<LifestyleLog> LogLifestyleAsync(Guid userId, LifestyleLogRequest req, CancellationToken ct = default)
    {
        var log = new LifestyleLog { Id = Guid.NewGuid(), UserId = userId, LogDate = req.LogDate,
            Category = req.Category, Value = req.Value };
        _db.Set<LifestyleLog>().Add(log);
        await _db.SaveChangesAsync(ct);
        return log;
    }

    public async Task<IReadOnlyList<Reminder>> GetRemindersAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<Reminder>().AsNoTracking().Where(r => r.UserId == userId && !r.IsDismissed)
            .OrderBy(r => r.RemindAt).ToListAsync(ct);

    public async Task DismissReminderAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var reminder = await _db.Set<Reminder>().FirstOrDefaultAsync(r => r.Id == id && r.UserId == userId, ct)
            ?? throw new NotFoundAppException();
        reminder.IsDismissed = true;
        await _db.SaveChangesAsync(ct);
    }

    // No PHI stored if unauthenticated.
    public async Task<SymptomCheck> SymptomCheckAsync(Guid? userId, SymptomCheckRequest req, CancellationToken ct = default)
    {
        var check = new SymptomCheck { Id = Guid.NewGuid(), UserId = userId, SymptomsJson = req.SymptomsJson };
        if (userId is not null)
        {
            _db.Set<SymptomCheck>().Add(check);
            await _db.SaveChangesAsync(ct);
        }
        return check;
    }
}
