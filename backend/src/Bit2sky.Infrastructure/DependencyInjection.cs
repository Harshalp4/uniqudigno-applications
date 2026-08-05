using Bit2sky.Application.Abstractions;
using Bit2sky.Infrastructure.Caching;
using Bit2sky.Infrastructure.Data;
using Bit2sky.Infrastructure.Security;
using Bit2sky.Shared.Options;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using StackExchange.Redis;

namespace Bit2sky.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        // Options.
        services.Configure<JwtOptions>(config.GetSection(JwtOptions.Section));
        services.Configure<PhiEncryptionOptions>(config.GetSection(PhiEncryptionOptions.Section));
        services.Configure<AzureKeyVaultOptions>(config.GetSection(AzureKeyVaultOptions.Section));

        // Persistence.
        services.AddDbContext<AppDbContext>(o =>
            o.UseNpgsql(config.GetConnectionString("Postgres")));
        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());

        // Redis multiplexer (lazy, degrades open if unreachable).
        var redisConn = config.GetConnectionString("Redis") ?? "localhost:6379";
        services.AddSingleton<IConnectionMultiplexer>(_ =>
        {
            var opts = ConfigurationOptions.Parse(redisConn);
            opts.AbortOnConnectFail = false;
            return ConnectionMultiplexer.Connect(opts);
        });

        // Security services.
        services.AddSingleton<JwtService>();
        services.AddSingleton<IJwtService>(sp => sp.GetRequiredService<JwtService>());
        services.AddSingleton<IPhiEncryptionService, PhiEncryptionService>();
        services.AddSingleton<ITotpService, TotpService>();
        services.AddSingleton<IKeyVaultService, KeyVaultService>();
        services.AddSingleton<IHashService, HashService>();

        // Caching + rate limiting.
        services.AddSingleton<ICacheService, RedisCacheService>();
        services.AddSingleton<IRateLimitService, RedisRateLimitService>();

        // Integrations.
        services.AddSingleton<IRazorpayService, Payments.RazorpayService>();
        services.AddSingleton<IStorageService, Storage.AzureBlobService>();
        services.AddSingleton<IClaudeAiService, AI.ClaudeAiService>();

        // Notifications: channels + orchestrator (WhatsApp-first, SMS fallback).
        services.AddSingleton<INotificationChannel, Notifications.WhatsAppNotificationService>();
        services.AddSingleton<INotificationChannel, Notifications.FcmNotificationService>();
        services.AddSingleton<INotificationChannel, Notifications.SmsNotificationService>();
        services.AddSingleton<INotificationChannel, Notifications.EmailNotificationService>();
        services.AddScoped<INotificationOrchestrator, Notifications.NotificationOrchestrator>();
        services.AddScoped<IEmailSender, Notifications.ResendEmailSender>();
        services.AddHttpClient(); // used for Google ID-token validation

        // Background jobs (scheduled in Program).
        services.AddScoped<BackgroundJobs.ExpiredTokenCleanupJob>();
        services.AddScoped<BackgroundJobs.GroupBookingExpiryJob>();
        services.AddScoped<BackgroundJobs.CashbackCreditJob>();
        services.AddScoped<BackgroundJobs.HealthScoreRecalcJob>();
        services.AddScoped<BackgroundJobs.SubscriptionReminderJob>();
        services.AddScoped<BackgroundJobs.RetestReminderJob>();
        services.AddScoped<BackgroundJobs.SlaMonitorJob>();
        services.AddScoped<BackgroundJobs.SecurityAuditJob>();

        return services;
    }
}
