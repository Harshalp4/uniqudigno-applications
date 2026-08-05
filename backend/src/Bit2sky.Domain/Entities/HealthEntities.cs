using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// health.health_scores — computed score (weights from app_config).
public class HealthScore
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int Score { get; set; }                       // 0-100
    public string? Grade { get; set; }                   // Excellent/Good/Fair/Poor
    public string? BreakdownJson { get; set; }           // per-pillar contributions
    public DateTimeOffset CalculatedAt { get; set; }

    public User User { get; set; } = null!;
}

// health.lifestyle_logs — diet/sleep/exercise/stress logs.
public class LifestyleLog
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateOnly LogDate { get; set; }
    public string Category { get; set; } = null!;        // sleep|diet|exercise|stress|water
    public string? Value { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

// health.vitals.
public class Vital
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public VitalType Type { get; set; }
    public string Value { get; set; } = null!;           // e.g. "120/80"
    public string? Unit { get; set; }
    public VitalSource Source { get; set; } = VitalSource.Manual;
    public DateTimeOffset RecordedAt { get; set; }

    public User User { get; set; } = null!;
}

// health.steps.
public class StepEntry
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateOnly Date { get; set; }
    public int Steps { get; set; }
    public VitalSource Source { get; set; } = VitalSource.Manual;
    public DateTimeOffset CreatedAt { get; set; }
}

// health.reminders.
public class Reminder
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public ReminderType Type { get; set; }
    public string Title { get; set; } = null!;
    public string? Notes { get; set; }
    public DateTimeOffset RemindAt { get; set; }
    public bool IsRecurring { get; set; }
    public string? RecurrenceRule { get; set; }
    public bool IsDismissed { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}

// health.symptom_checks — no PHI stored if unauthenticated.
public class SymptomCheck
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string SymptomsJson { get; set; } = null!;
    public string? ResultJson { get; set; }
    public string? RecommendedTestsJson { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
