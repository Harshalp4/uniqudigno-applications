namespace Bit2sky.Domain.Enums;

// core.security_events.event_type CHECK constraint (Section 6).
public enum SecurityEventType
{
    OtpMaxAttempts,
    TokenReuseDetected,
    LoginLocked,
    AdminNewIp,
    BulkDownloadDetected,
    RateLimitBlocked,
    JwtReuseDetected,
    PermissionEscalationAttempt,
    SsrfAttempt,
    InvalidFileUpload
}
