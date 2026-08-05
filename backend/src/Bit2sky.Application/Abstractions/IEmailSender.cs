namespace Bit2sky.Application.Abstractions;

/// Sends transactional email. The dev implementation logs the message; a real
/// provider (Resend/SES/SMTP) is dropped in for production.
public interface IEmailSender
{
    Task SendOtpAsync(string email, string otp, CancellationToken ct = default);
}
