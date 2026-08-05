using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Notifications;

/// Dev/default email sender — logs the OTP instead of dispatching mail. Swap for
/// a Resend/SES/SMTP implementation in production (register a different IEmailSender).
public class LoggingEmailSender : IEmailSender
{
    private readonly ILogger<LoggingEmailSender> _log;
    public LoggingEmailSender(ILogger<LoggingEmailSender> log) => _log = log;

    public Task SendOtpAsync(string email, string otp, CancellationToken ct = default)
    {
        _log.LogInformation("EMAIL OTP for {Email}: {Otp} (dev sender — not actually emailed)", email, otp);
        return Task.CompletedTask;
    }
}
