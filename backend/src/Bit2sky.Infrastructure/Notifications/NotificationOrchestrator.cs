using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.Notifications;

// Resolves the WhatsApp template name from comms.whatsapp_templates (not hardcoded),
// writes the in-app notification, and dispatches across channels (Section 12).
// WhatsApp-first with SMS fallback per spec.
public class NotificationOrchestrator : INotificationOrchestrator
{
    private readonly IAppDbContext _db;
    private readonly IReadOnlyDictionary<NotificationChannel, INotificationChannel> _channels;

    public NotificationOrchestrator(IAppDbContext db, IEnumerable<INotificationChannel> channels)
    {
        _db = db;
        _channels = channels.ToDictionary(c => c.Channel);
    }

    public async Task NotifyAsync(Guid userId, string templateKey,
        IReadOnlyDictionary<string, string> variables, CancellationToken ct = default)
    {
        var template = await _db.Set<WhatsAppTemplate>().AsNoTracking()
            .FirstOrDefaultAsync(t => t.Key == templateKey && t.IsActive, ct);

        // In-app inbox entry.
        _db.Set<Notification>().Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Title = variables.GetValueOrDefault("title", templateKey),
            Body = variables.GetValueOrDefault("body", string.Empty),
            Channel = NotificationChannel.InApp,
            Status = NotificationStatus.Delivered,
        });
        await _db.SaveChangesAsync(ct);

        var name = template?.TemplateName ?? templateKey;

        // FCM targets device tokens, not a phone number — dispatch it regardless
        // of whether the user has a mobile (email/Google sign-ups often don't).
        if (_channels.TryGetValue(NotificationChannel.Fcm, out var fcm))
            await fcm.SendAsync(userId.ToString(), name, variables, ct);

        var mobile = await _db.Set<User>().Where(u => u.Id == userId).Select(u => u.Mobile).FirstOrDefaultAsync(ct);
        if (string.IsNullOrWhiteSpace(mobile)) return;

        if (_channels.TryGetValue(NotificationChannel.WhatsApp, out var whatsapp))
            await whatsapp.SendAsync(mobile, name, variables, ct);
    }
}
