using System.Linq;
using System.Security.Cryptography;
using Bit2sky.Infrastructure.Data;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Bit2sky.IntegrationTests;

// Boots the real API with an in-memory database, jobs disabled, and a shared RSA
// keypair so issued JWTs validate. No Postgres/Redis required.
// Config is injected via UseSetting (not ConfigureAppConfiguration) so it's available
// before Program reads Jobs:Enabled and the JWT keys at startup.
public class TestWebAppFactory : WebApplicationFactory<Program>
{
    public string PrivateKeyPem { get; }
    public string PublicKeyPem { get; }

    public TestWebAppFactory()
    {
        using var rsa = RSA.Create(2048);
        PrivateKeyPem = rsa.ExportRSAPrivateKeyPem();
        PublicKeyPem = rsa.ExportSubjectPublicKeyInfoPem();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.UseSetting("Jobs:Enabled", "false");
        builder.UseSetting("Jwt:Issuer", "vitalscan-auth");
        builder.UseSetting("Jwt:Audience", "vitalscan-api");
        builder.UseSetting("Jwt:PrivateKeyPem", PrivateKeyPem);
        builder.UseSetting("Jwt:PublicKeyPem", PublicKeyPem);
        builder.UseSetting("ConnectionStrings:Redis", "localhost:6379");

        builder.ConfigureTestServices(services =>
        {
            // Swap Npgsql AppDbContext for an in-memory store. Remove every EF
            // options/configuration descriptor first, or both providers end up
            // registered (Npgsql + InMemory).
            var efDescriptors = services.Where(d =>
                d.ServiceType == typeof(DbContextOptions<AppDbContext>) ||
                d.ServiceType == typeof(DbContextOptions) ||
                d.ServiceType == typeof(AppDbContext) ||
                (d.ServiceType.Name.StartsWith("IDbContextOptionsConfiguration") &&
                 d.ServiceType.GenericTypeArguments.Contains(typeof(AppDbContext)))).ToList();
            foreach (var d in efDescriptors) services.Remove(d);
            services.AddDbContext<AppDbContext>(o => o.UseInMemoryDatabase("bit2sky-tests"));

            // Swap Redis distributed cache for an in-memory one.
            services.RemoveAll<IDistributedCache>();
            services.AddDistributedMemoryCache();

            // Avoid a real Redis connection attempt during the rate limiter.
            services.RemoveAll<StackExchange.Redis.IConnectionMultiplexer>();
            services.AddSingleton<Bit2sky.Application.Abstractions.IRateLimitService, NoopRateLimitService>();
        });
    }
}

// Allows all requests — keeps integration tests free of a Redis dependency.
internal sealed class NoopRateLimitService : Bit2sky.Application.Abstractions.IRateLimitService
{
    public Task<(bool Allowed, int RetryAfterSeconds)> CheckAsync(
        string key, int limit, TimeSpan window, CancellationToken ct = default)
        => Task.FromResult((true, 0));
}
