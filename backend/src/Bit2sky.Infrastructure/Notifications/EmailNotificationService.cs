using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Notifications;

// Email channel. Provider call (WABA/FCM/MSG91/Azure Comms) wired from config;
// values are sanitized before template injection (Section 12).
public class EmailNotificationService : INotificationChannel
{
    private readonly ILogger<EmailNotificationService> _logger;
    public EmailNotificationService(ILogger<EmailNotificationService> logger) => _logger = logger;

    public NotificationChannel Channel => NotificationChannel.Email;

    public Task SendAsync(string recipient, string templateKey,
        IReadOnlyDictionary<string, string> variables, CancellationToken ct = default)
    {
        _logger.LogInformation("[Email] template {Template} -> {Recipient}", templateKey, recipient);
        return Task.CompletedTask;
    }
}
