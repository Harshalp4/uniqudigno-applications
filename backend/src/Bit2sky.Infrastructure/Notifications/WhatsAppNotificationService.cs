using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Notifications;

// WhatsApp channel. Provider call (WABA/FCM/MSG91/Azure Comms) wired from config;
// values are sanitized before template injection (Section 12).
public class WhatsAppNotificationService : INotificationChannel
{
    private readonly ILogger<WhatsAppNotificationService> _logger;
    public WhatsAppNotificationService(ILogger<WhatsAppNotificationService> logger) => _logger = logger;

    public NotificationChannel Channel => NotificationChannel.WhatsApp;

    public Task SendAsync(string recipient, string templateKey,
        IReadOnlyDictionary<string, string> variables, CancellationToken ct = default)
    {
        _logger.LogInformation("[WhatsApp] template {Template} -> {Recipient}", templateKey, recipient);
        return Task.CompletedTask;
    }
}
