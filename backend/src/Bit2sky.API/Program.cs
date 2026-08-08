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
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// ── Managed-datastore URLs → driver connection strings ──────────────────────
// Render/Heroku-style hosts hand out postgresql:// and redis:// URLs, which
// neither Npgsql nor StackExchange.Redis can parse. No-op for keyword-style
// values, so local and Azure configs are unaffected.
Bit2sky.API.Configuration.ConnectionStringNormalizer.NormalizeInto(builder.Configuration);

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
// Origins come from Cors:AllowedOrigins so each environment sets its own; they
// were previously hardcoded to bit2sky.app domains that no longer apply. The
// mobile apps don't use CORS at all — this exists for the admin web portal.
const string CorsPolicy = "Bit2skyCors";
var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                  ?? Array.Empty<string>();
builder.Services.AddCors(o => o.AddPolicy(CorsPolicy, p =>
{
    // AllowCredentials with zero origins throws at startup; a browser-less
    // deployment (mobile only) is a legitimate configuration.
    if (corsOrigins.Length == 0) return;
    p.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
}));

// ── Auth: JWT RS256 (public key from Key Vault) ─────────────────────────────
// Env-var editors frequently mangle multi-line PEMs — newlines collapse to spaces
// or become literal "\n". Rebuild a well-formed PEM from the BEGIN/END markers +
// base64 body so a key pasted in any of those shapes still imports.
static string? NormalizePem(string? pem)
{
    if (string.IsNullOrWhiteSpace(pem)) return pem;
    var s = pem.Trim().Replace("\\r\\n", "\n").Replace("\\n", "\n")
               .Replace("\r\n", "\n").Replace('\r', '\n');
    var m = System.Text.RegularExpressions.Regex.Match(s,
        "-----BEGIN ([A-Z ]+)-----(.*?)-----END \\1-----",
        System.Text.RegularExpressions.RegexOptions.Singleline);
    if (!m.Success) return s; // not a PEM (e.g. a file path) — let import fail loudly
    var label = m.Groups[1].Value.Trim();
    var body = System.Text.RegularExpressions.Regex.Replace(m.Groups[2].Value, "\\s+", "");
    var sb = new System.Text.StringBuilder().Append("-----BEGIN ").Append(label).Append("-----\n");
    for (var i = 0; i < body.Length; i += 64)
        sb.Append(body, i, System.Math.Min(64, body.Length - i)).Append('\n');
    return sb.Append("-----END ").Append(label).Append("-----\n").ToString();
}

var jwt = builder.Configuration.GetSection(JwtOptions.Section).Get<JwtOptions>() ?? new JwtOptions();
var rsa = RSA.Create(2048);
var publicPem = NormalizePem(jwt.PublicKeyPem);
var privatePem = NormalizePem(jwt.PrivateKeyPem);
if (!string.IsNullOrWhiteSpace(publicPem)) rsa.ImportFromPem(publicPem);
else if (!string.IsNullOrWhiteSpace(privatePem)) rsa.ImportFromPem(privatePem);
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

// ── Caching: Redis (L2) when configured, else in-memory ─────────────────────
// A Redis connection string switches on the distributed L2 cache. When it's
// empty (e.g. a single free-tier instance with no Redis), fall back to an
// in-process IDistributedCache so the app runs without a Redis dependency.
var redisConn = builder.Configuration.GetConnectionString("Redis");
if (!string.IsNullOrWhiteSpace(redisConn))
    builder.Services.AddStackExchangeRedisCache(o =>
    {
        o.Configuration = redisConn;
        o.InstanceName = "bit2sky:";
    });
else
    builder.Services.AddDistributedMemoryCache();

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

// ── Migrate / seed: `dotnet Bit2sky.API.dll migrate|seed` (no-op on startup) ─
// `migrate` applies schema only and is what the deploy pipeline runs on every
// release. `seed` additionally writes reference/demo data and must NOT run
// against production on each deploy — hence the two separate verbs.
var runMigrate = args.Contains("migrate", StringComparer.OrdinalIgnoreCase);
var runSeed = args.Contains("seed", StringComparer.OrdinalIgnoreCase);
if (runMigrate || runSeed)
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<Bit2sky.Infrastructure.Data.AppDbContext>();
    await db.Database.MigrateAsync();
    Log.Information("Migrations applied.");

    if (runSeed)
    {
        var hasher = scope.ServiceProvider.GetRequiredService<Bit2sky.Application.Abstractions.IHashService>();
        await Bit2sky.Infrastructure.Data.DataSeeder.SeedAsync(db, hasher);
        Log.Information("Seed complete.");
    }
    return;
}

// Apply migrations on startup when the host has no pre-deploy hook to run the
// `migrate` verb (e.g. Render free tier, which doesn't support preDeployCommand).
// Off by default; set AutoMigrate=true. Paid deploys keep using the verb.
if (app.Configuration.GetValue("AutoMigrate", false))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<Bit2sky.Infrastructure.Data.AppDbContext>();
    await db.Database.MigrateAsync();
    Log.Information("Migrations applied on startup (AutoMigrate).");
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

// Render (and any TLS-terminating proxy) forwards the request over plain HTTP
// with the original scheme in X-Forwarded-Proto. Without honouring that,
// UseHttpsRedirection sees "http", 307s to https, the proxy forwards as http
// again, and the request loops until the browser gives up. This must run before
// UseHttpsRedirection. KnownNetworks/Proxies are cleared because the proxy hop
// is inside the platform's network and its address isn't known ahead of time.
var forwarded = new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor,
};
forwarded.KnownIPNetworks.Clear();
forwarded.KnownProxies.Clear();
app.UseForwardedHeaders(forwarded);

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
// GET and HEAD — uptime pingers (e.g. UptimeRobot) default to HEAD, which a
// GET-only route answers with 405 and flags as "down".
app.MapMethods("/health", new[] { "GET", "HEAD" }, () => Results.Ok(new { status = "healthy" }));

app.Run();

public partial class Program { }
