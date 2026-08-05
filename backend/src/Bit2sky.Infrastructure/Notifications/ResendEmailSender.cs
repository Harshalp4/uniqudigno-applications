using System.Net.Http.Headers;
using System.Net.Http.Json;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Notifications;

/// Sends email OTPs via Resend (https://resend.com), mirroring PRESSO's
/// ResendEmailOtpService. When no API key is configured it logs the code (dev)
/// instead of failing, so email login still works locally via the dev echo.
public class ResendEmailSender : IEmailSender
{
    private const string ResendUrl = "https://api.resend.com/emails";
    private readonly IConfiguration _config;
    private readonly IHttpClientFactory _httpFactory;
    private readonly ILogger<ResendEmailSender> _log;

    public ResendEmailSender(IConfiguration config, IHttpClientFactory httpFactory,
        ILogger<ResendEmailSender> log)
    {
        _config = config;
        _httpFactory = httpFactory;
        _log = log;
    }

    public async Task SendOtpAsync(string email, string otp, CancellationToken ct = default)
    {
        var apiKey = _config["Email:ResendApiKey"];
        var from = _config["Email:FromAddress"] ?? "Unique Diagnostic Centre <noreply@vitalscan.app>";

        if (string.IsNullOrWhiteSpace(apiKey) || apiKey == "YOUR_RESEND_API_KEY")
        {
            _log.LogWarning(
                "Resend not configured — OTP for {Email}: {Otp} (dev only, not emailed)", email, otp);
            return;
        }

        var html =
            "<div style=\"font-family:Arial,sans-serif;font-size:16px;color:#222\">" +
            "<p>Your Unique Diagnostic Centre verification code is:</p>" +
            $"<p style=\"font-size:28px;font-weight:700;letter-spacing:4px\">{otp}</p>" +
            "<p style=\"color:#666\">It expires in 5 minutes. If you didn't request this, ignore this email.</p>" +
            "</div>";

        var payload = new
        {
            from,
            to = new[] { email },
            subject = "Your Unique Diagnostic Centre verification code",
            html,
        };

        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, ResendUrl)
            {
                Content = JsonContent.Create(payload),
            };
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            var res = await _httpFactory.CreateClient().SendAsync(req, ct);
            if (!res.IsSuccessStatusCode)
                _log.LogError("Resend send failed for {Email}: {Status}", email, res.StatusCode);
        }
        catch (Exception ex)
        {
            _log.LogError(ex, "Resend send threw for {Email}", email);
        }
    }
}
