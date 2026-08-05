namespace Bit2sky.Domain.Entities;

// core.refresh_tokens — full model (Section 4A + Section 6 security additions).
public class RefreshToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public string TokenHash { get; set; } = null!;        // SHA-256 hash, never plaintext
    public string DeviceId { get; set; } = null!;         // SHA256(device_info) binding
    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset? RevokedAt { get; set; }
    public string? ReplacedByTokenHash { get; set; }      // rotation chain

    // ── Security additions (v3 Section 6) ──────────────────────────────────────
    public Guid TokenFamily { get; set; }                 // all tokens in same login family
    public bool IsTheftDetected { get; set; }
    public DateTimeOffset? ReusedAt { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
