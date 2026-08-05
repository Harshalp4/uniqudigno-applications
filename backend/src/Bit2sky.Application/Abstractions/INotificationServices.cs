using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;

namespace Bit2sky.Application.Abstractions;

// In-app notification inbox (own only).
public interface INotificationService
{
    Task<IReadOnlyList<Notification>> ListAsync(Guid userId, CancellationToken ct = default);
    Task<int> UnreadCountAsync(Guid userId, CancellationToken ct = default);
    Task MarkReadAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task MarkAllReadAsync(Guid userId, CancellationToken ct = default);
    Task RegisterDeviceAsync(Guid userId, string fcmToken, DevicePlatform platform, CancellationToken ct = default);

    // Admin (Section 11/12): broadcast an in-app notification to all active users; recent feed.
    Task<int> BroadcastAsync(string title, string body, string? deepLink, CancellationToken ct = default);
    Task<IReadOnlyList<Notification>> RecentAsync(int take, CancellationToken ct = default);
}

// One outbound channel (WhatsApp / FCM / SMS / Email).
public interface INotificationChannel
{
    NotificationChannel Channel { get; }
    Task SendAsync(string recipient, string templateKey, IReadOnlyDictionary<string, string> variables, CancellationToken ct = default);
}

// Resolves the template (from DB) and dispatches via the appropriate channels (Section 12).
public interface INotificationOrchestrator
{
    Task NotifyAsync(Guid userId, string templateKey, IReadOnlyDictionary<string, string> variables, CancellationToken ct = default);
}
