using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// comms.notifications (own only).
public class Notification
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Title { get; set; } = null!;
    public string Body { get; set; } = null!;
    public NotificationChannel Channel { get; set; } = NotificationChannel.InApp;
    public NotificationStatus Status { get; set; } = NotificationStatus.Pending;
    public string? DeepLink { get; set; }
    public string? DataJson { get; set; }
    public bool IsRead { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? ReadAt { get; set; }

    public User User { get; set; } = null!;
}

// comms.ai_sessions (PHI — own only).
public class AiSession
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string? Title { get; set; }
    public AiSessionStatus Status { get; set; } = AiSessionStatus.Active;
    public Guid? PromptVersionId { get; set; }           // ai_prompts version used
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<AiChatMessage> Messages { get; set; } = new List<AiChatMessage>();
}

// comms.ai_chat_messages (PHI — content encrypted at rest, never PII-linked in logs).
public class AiChatMessage
{
    public Guid Id { get; set; }
    public Guid SessionId { get; set; }
    public AiMessageRole Role { get; set; }
    public string Content { get; set; } = null!;         // encrypted at rest
    public int? TokensUsed { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public AiSession Session { get; set; } = null!;
}

// comms.support_tickets (own only).
public class SupportTicket
{
    public Guid Id { get; set; }
    public string TicketNumber { get; set; } = null!;    // UNIQUE
    public Guid UserId { get; set; }
    public string Subject { get; set; } = null!;
    public string Category { get; set; } = "general";
    public TicketStatus Status { get; set; } = TicketStatus.Open;
    public TicketPriority Priority { get; set; } = TicketPriority.Medium;
    public Guid? AssignedToAdminId { get; set; }
    public Guid? RelatedBookingId { get; set; }
    public DateTimeOffset? SlaDueAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<SupportMessage> Messages { get; set; } = new List<SupportMessage>();
}

// comms.support_messages.
public class SupportMessage
{
    public Guid Id { get; set; }
    public Guid TicketId { get; set; }
    public Guid? SenderUserId { get; set; }
    public bool IsFromAgent { get; set; }
    public string Body { get; set; } = null!;
    public string? AttachmentUrl { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public SupportTicket Ticket { get; set; } = null!;
}

// comms.whatsapp_templates — template name mapping (not hardcoded).
public class WhatsAppTemplate
{
    public Guid Id { get; set; }
    public string Key { get; set; } = null!;             // internal event key, UNIQUE
    public string TemplateName { get; set; } = null!;    // WABA-approved name
    public string LanguageCode { get; set; } = "en";
    public string? VariablesJson { get; set; }           // ordered variable mapping
    public bool IsActive { get; set; } = true;
    public DateTimeOffset UpdatedAt { get; set; }
}
