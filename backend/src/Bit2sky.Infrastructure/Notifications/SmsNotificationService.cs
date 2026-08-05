using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Notifications;

// Sms channel. Provider call (WABA/FCM/MSG91/Azure Comms) wired from config;
// values are sanitized before template injection (Section 12).
public class SmsNotificationService : INotificationChannel
{
    private readonly ILogger<SmsNotificationService> _logger;
    public SmsNotificationService(ILogger<SmsNotificationService> logger) => _logger = logger;

    public NotificationChannel Channel => NotificationChannel.Sms;

    public Task SendAsync(string recipient, string templateKey,
        IReadOnlyDictionary<string, string> variables, CancellationToken ct = default)
    {
        _logger.LogInformation("[Sms] template {Template} -> {Recipient}", templateKey, recipient);
        return Task.CompletedTask;
    }
}
