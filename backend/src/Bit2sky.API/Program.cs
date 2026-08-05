using System.Security.Cryptography;
using System.Threading.RateLimiting;
using Azure.Identity;
using Bit2sky.API.Hubs;
using Bit2sky.API.Middleware;
using Bit2sky.API.Security;
using Bit2sky.Application;
using Bit2sky.Application.Abstractions;
using Bit2sky.Infrastructure;
using Bit2sky.Shared.Options;
using Hangfire;
using Hangfire.PostgreSql;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// ── Configuration: Azure Key Vault (all secrets) ────────────────────────────
var keyVaultUri = builder.Configuration["Azure:KeyVault:Uri"];
if (!string.IsNullOrWhiteSpace(keyVaultUri))
    builder.Configuration.AddAzureKeyVault(new Uri(keyVaultUri), new DefaultAzureCredential());

// ── Logging: Serilog (PHI-scrubbed) ─────────────────────────────────────────
builder.Host.UseSerilog((ctx, cfg) =>
    cfg.ReadFrom.Configuration(ctx.Configuration).Enrich.FromLogContext());

// ── Layers ──────────────────────────────────────────────────────────────────
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddApplication();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();
builder.Services.AddScoped<IBookingEventsPublisher, Bit2sky.API.Realtime.SignalRBookingEventsPublisher>();

// ── CORS (explicit origins, no wildcard) ────────────────────────────────────
const string CorsPolicy = "Bit2skyCors";
builder.Services.AddCors(o => o.AddPolicy(CorsPolicy, p =>
    p.WithOrigins(
        "https://admin.Bit2sky.app", "https://Bit2sky.app",
        // Local admin-portal development (ng serve).
        "http://localhost:4200", "http://localhost:4300")
     .AllowAnyHeader().AllowAnyMethod().AllowCredentials()));

// ── Auth: JWT RS256 (public key from Key Vault) ─────────────────────────────
var jwt = builder.Configuration.GetSection(JwtOptions.Section).Get<JwtOptions>() ?? new JwtOptions();
var rsa = RSA.Create(2048);
if (!string.IsNullOrWhiteSpace(jwt.PublicKeyPem)) rsa.ImportFromPem(jwt.PublicKeyPem);
else if (!string.IsNullOrWhiteSpace(jwt.PrivateKeyPem)) rsa.ImportFromPem(jwt.PrivateKeyPem);
var validationKey = new RsaSecurityKey(rsa) { KeyId = jwt.KeyId };

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = validationKey,
            ValidAlgorithms = new[] { SecurityAlgorithms.RsaSha256 },
            NameClaimType = "sub",
            RoleClaimType = "role",
        };
        // SignalR WebSocket/SSE clients can't set an Authorization header — they
        // pass the JWT as ?access_token=, accepted for hub paths only.
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var accessToken = ctx.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(accessToken) &&
                    ctx.HttpContext.Request.Path.StartsWithSegments("/hubs"))
                    ctx.Token = accessToken;
                return Task.CompletedTask;
            },
        };
    });
builder.Services.AddAuthorization();

// ── Caching (L2 Redis) ──────────────────────────────────────────────────────
builder.Services.AddStackExchangeRedisCache(o =>
{
    o.Configuration = builder.Configuration.GetConnectionString("Redis");
    o.InstanceName = "bit2sky:";
});

// ── Built-in rate limiter (Redis-distributed layer applied per-endpoint) ────
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddSlidingWindowLimiter("default", l =>
    {
        l.PermitLimit = 100;
        l.Window = TimeSpan.FromMinutes(1);
        l.SegmentsPerWindow = 6;
        l.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        l.QueueLimit = 0;
    });
});

// ── Background jobs: Hangfire (PostgreSQL) ──────────────────────────────────
// Gated so integration tests / job-less hosts boot without a Postgres connection.
var jobsEnabled = builder.Configuration.GetValue("Jobs:Enabled", true);
if (jobsEnabled)
{
    builder.Services.AddHangfire(c => c
        .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
        .UseSimpleAssemblyNameTypeSerializer()
        .UseRecommendedSerializerSettings()
        .UsePostgreSqlStorage(p => p.UseNpgsqlConnection(builder.Configuration.GetConnectionString("Postgres"))));
    builder.Services.AddHangfireServer();
}

// ── Real-time + MVC + docs ──────────────────────────────────────────────────
builder.Services.AddSignalR();
builder.Services.AddControllers(o => o.Filters.Add<Bit2sky.API.Validation.ValidationActionFilter>())
    // Enums serialize as their names (e.g. "Confirmed", "Banner") so clients read
    // stable strings instead of brittle integers — the whole app is data-driven.
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
        // Entities have back-references (e.g. FamilyMember.User -> User.FamilyMembers);
        // drop cycles instead of throwing at depth 32 and corrupting the response.
        o.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
// Keep manually-written JSON (e.g. the exception middleware) consistent.
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    o.SerializerOptions.ReferenceHandler =
        System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// ── Migrate + seed: `dotnet run -- seed` (no-op on normal startup) ───────────
if (args.Contains("seed", StringComparer.OrdinalIgnoreCase))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<Bit2sky.Infrastructure.Data.AppDbContext>();
    var hasher = scope.ServiceProvider.GetRequiredService<Bit2sky.Application.Abstractions.IHashService>();
    await db.Database.MigrateAsync();
    await Bit2sky.Infrastructure.Data.DataSeeder.SeedAsync(db, hasher);
    Log.Information("Seed complete.");
    return;
}

// ── Swagger: dev + staging only ─────────────────────────────────────────────
if (app.Environment.IsDevelopment() || app.Environment.IsStaging())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ── Pipeline ────────────────────────────────────────────────────────────────
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseMiddleware<AppSourceMiddleware>();

app.UseHttpsRedirection();
app.UseCors(CorsPolicy);

app.UseAuthentication();
app.UseAuthorization();

app.UseRateLimiter();
app.UseMiddleware<AuditLoggingMiddleware>();

// ── Endpoints ───────────────────────────────────────────────────────────────
app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notifications");
app.MapHub<BookingTrackingHub>("/hubs/booking-tracking");

// ── Recurring background jobs (Section 16) ───────────────────────────────────
if (jobsEnabled)
{
app.UseHangfireDashboard("/hangfire");
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.ExpiredTokenCleanupJob>(
    "expired-token-cleanup", j => j.ExecuteAsync(CancellationToken.None), Cron.Daily);
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.GroupBookingExpiryJob>(
    "group-booking-expiry", j => j.ExecuteAsync(CancellationToken.None), Cron.Hourly);
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.CashbackCreditJob>(
    "cashback-credit", j => j.ExecuteAsync(CancellationToken.None), Cron.Hourly);
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.HealthScoreRecalcJob>(
    "health-score-recalc", j => j.ExecuteAsync(CancellationToken.None), Cron.Daily);
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.SubscriptionReminderJob>(
    "subscription-reminder", j => j.ExecuteAsync(CancellationToken.None), Cron.Daily);
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.RetestReminderJob>(
    "retest-reminder", j => j.ExecuteAsync(CancellationToken.None), Cron.Daily);
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.SlaMonitorJob>(
    "sla-monitor", j => j.ExecuteAsync(CancellationToken.None), "*/15 * * * *");
RecurringJob.AddOrUpdate<Bit2sky.Infrastructure.BackgroundJobs.SecurityAuditJob>(
    "security-audit", j => j.ExecuteAsync(CancellationToken.None), Cron.Weekly);
}

// JWKS endpoint (Section 4A / Section 7).
app.MapGet("/.well-known/jwks.json", (IJwtService j) => Results.Content(j.GetJwksJson(), "application/json"));
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.Run();

public partial class Program { }
