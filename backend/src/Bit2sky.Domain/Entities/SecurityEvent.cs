using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// core.security_events (Section 6 — fully specified in v3).
public class SecurityEvent
{
    public Guid Id { get; set; }
    public SecurityEventType EventType { get; set; }
    public Guid? UserId { get; set; }                 // references core.users(id)
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Details { get; set; }              // JSONB
    public SecurityEventSeverity Severity { get; set; }
    public bool Resolved { get; set; }
    public Guid? ResolvedBy { get; set; }             // references core.users(id)
    public DateTimeOffset? ResolvedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User? User { get; set; }
}
