using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Bit2sky.Infrastructure.Data.Configurations;

public class SecurityEventConfiguration : IEntityTypeConfiguration<SecurityEvent>
{
    // event_type enum ↔ exact DB strings from the CHECK constraint.
    private static readonly Dictionary<SecurityEventType, string> EventTypeMap = new()
    {
        [SecurityEventType.OtpMaxAttempts] = "otp_max_attempts",
        [SecurityEventType.TokenReuseDetected] = "token_reuse_detected",
        [SecurityEventType.LoginLocked] = "login_locked",
        [SecurityEventType.AdminNewIp] = "admin_new_ip",
        [SecurityEventType.BulkDownloadDetected] = "bulk_download_detected",
        [SecurityEventType.RateLimitBlocked] = "rate_limit_blocked",
        [SecurityEventType.JwtReuseDetected] = "jwt_reuse_detected",
        [SecurityEventType.PermissionEscalationAttempt] = "permission_escalation_attempt",
        [SecurityEventType.SsrfAttempt] = "ssrf_attempt",
        [SecurityEventType.InvalidFileUpload] = "invalid_file_upload",
    };

    public void Configure(EntityTypeBuilder<SecurityEvent> b)
    {
        b.ToTable("security_events", "core", t =>
        {
            t.HasCheckConstraint("ck_security_events_event_type",
                "event_type IN ('otp_max_attempts','token_reuse_detected','login_locked'," +
                "'admin_new_ip','bulk_download_detected','rate_limit_blocked'," +
                "'jwt_reuse_detected','permission_escalation_attempt'," +
                "'ssrf_attempt','invalid_file_upload')");
            t.HasCheckConstraint("ck_security_events_severity",
                "severity IN ('low','medium','high','critical')");
        });

        b.HasKey(x => x.Id);

        b.Property(x => x.EventType)
            .HasColumnName("event_type")
            .HasMaxLength(50)
            .IsRequired()
            .HasConversion(
                v => EventTypeMap[v],
                v => EventTypeMap.First(kv => kv.Value == v).Key);

        b.Property(x => x.IpAddress).HasMaxLength(45);

        b.Property(x => x.Details).HasColumnType("jsonb");

        b.Property(x => x.Severity)
            .HasMaxLength(10)
            .IsRequired()
            .HasConversion(
                v => v.ToString().ToLowerInvariant(),
                v => Enum.Parse<SecurityEventSeverity>(v, ignoreCase: true));

        b.Property(x => x.Resolved).HasDefaultValue(false);
        b.Property(x => x.CreatedAt).HasDefaultValueSql("now()");

        // INDEX idx_security_events_type ON (event_type, severity, created_at DESC)
        b.HasIndex(x => new { x.EventType, x.Severity, x.CreatedAt })
            .HasDatabaseName("idx_security_events_type")
            .IsDescending(false, false, true);

        b.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // resolved_by → core.users(id), no inverse navigation
        b.HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.ResolvedBy)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
