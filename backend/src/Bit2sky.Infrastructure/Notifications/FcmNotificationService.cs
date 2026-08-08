using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using FcmNotification = FirebaseAdmin.Messaging.Notification;

namespace Bit2sky.Infrastructure.Notifications;

// Firebase Cloud Messaging channel. Looks up the recipient's active device
// tokens and pushes a notification via the Firebase Admin SDK. Degrades to a
// no-op (logs only) when no service-account credentials are configured, so the
// app runs on the free tier until Firebase:ServiceAccountJson is set.
public class FcmNotificationService : INotificationChannel
{
    private readonly ILogger<FcmNotificationService> _logger;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IConfiguration _config;

    // FirebaseApp is process-wide; initialise it once, lazily, guarding against
    // races and re-tries after a failed init.
    private static readonly object InitLock = new();
    private static bool _initTried;
    private static FirebaseApp? _app;

    public FcmNotificationService(
        ILogger<FcmNotificationService> logger,
        IServiceScopeFactory scopeFactory,
        IConfiguration config)
    {
        _logger = logger;
        _scopeFactory = scopeFactory;
        _config = config;
    }

    public NotificationChannel Channel => NotificationChannel.Fcm;

    public async Task SendAsync(string recipient, string templateKey,
        IReadOnlyDictionary<string, string> variables, CancellationToken ct = default)
    {
        var app = EnsureApp();
        if (app is null)
        {
            _logger.LogInformation("[Fcm] not configured — skipping push {Template} -> {Recipient}",
                templateKey, recipient);
            return;
        }
        if (!Guid.TryParse(recipient, out var userId)) return;

        // Load the user's active device tokens in a fresh scope (this service is
        // a singleton; the DbContext is scoped).
        List<Device> devices;
        using (var scope = _scopeFactory.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
            devices = await db.Set<Device>()
                .Where(d => d.UserId == userId && d.IsActive && d.FcmToken != "")
                .ToListAsync(ct);
        }
        if (devices.Count == 0) return;

        var title = variables.GetValueOrDefault("title", templateKey);
        var body = variables.GetValueOrDefault("body", string.Empty);
        // Carry the rest as data so the app can deep-link; FCM data values must be strings.
        var data = variables
            .Where(kv => kv.Key is not ("title" or "body"))
            .ToDictionary(kv => kv.Key, kv => kv.Value);

        var message = new MulticastMessage
        {
            Tokens = devices.Select(d => d.FcmToken).ToList(),
            Notification = new FcmNotification { Title = title, Body = body },
            Data = data.Count > 0 ? data : null,
            Android = new AndroidConfig { Priority = Priority.High },
        };

        BatchResponse response;
        try
        {
            response = await FirebaseMessaging.GetMessaging(app).SendEachForMulticastAsync(message, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Fcm] send failed for {Recipient}", recipient);
            return;
        }

        if (response.FailureCount == 0) return;

        // Deactivate tokens FCM reports as permanently gone so we stop targeting them.
        var stale = new List<string>();
        for (var i = 0; i < response.Responses.Count; i++)
        {
            var r = response.Responses[i];
            if (r.IsSuccess) continue;
            var code = (r.Exception as FirebaseMessagingException)?.MessagingErrorCode;
            if (code is MessagingErrorCode.Unregistered or MessagingErrorCode.InvalidArgument)
                stale.Add(devices[i].FcmToken);
        }
        if (stale.Count > 0) await DeactivateAsync(stale, ct);
    }

    private async Task DeactivateAsync(List<string> tokens, CancellationToken ct)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
            var rows = await db.Set<Device>().Where(d => tokens.Contains(d.FcmToken)).ToListAsync(ct);
            foreach (var d in rows) d.IsActive = false;
            await db.SaveChangesAsync(ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "[Fcm] failed to deactivate {Count} stale tokens", tokens.Count);
        }
    }

    private FirebaseApp? EnsureApp()
    {
        if (_initTried) return _app;
        lock (InitLock)
        {
            if (_initTried) return _app;
            _initTried = true;

            var json = _config["Firebase:ServiceAccountJson"];
            if (string.IsNullOrWhiteSpace(json))
            {
                _app = null;
                return null;
            }
            try
            {
                _app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
                {
                    Credential = GoogleCredential.FromJson(json),
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Fcm] failed to initialise FirebaseApp — push disabled");
                _app = null;
            }
            return _app;
        }
    }
}
