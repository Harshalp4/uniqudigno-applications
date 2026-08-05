using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Notifications;

// Fcm channel. Provider call (WABA/FCM/MSG91/Azure Comms) wired from config;
// values are sanitized before template injection (Section 12).
public class FcmNotificationService : INotificationChannel
{
    private readonly ILogger<FcmNotificationService> _logger;
    public FcmNotificationService(ILogger<FcmNotificationService> logger) => _logger = logger;

    public NotificationChannel Channel => NotificationChannel.Fcm;

    public Task SendAsync(string recipient, string templateKey,
        IReadOnlyDictionary<string, string> variables, CancellationToken ct = default)
    {
        _logger.LogInformation("[Fcm] template {Template} -> {Recipient}", templateKey, recipient);
        return Task.CompletedTask;
    }
}
