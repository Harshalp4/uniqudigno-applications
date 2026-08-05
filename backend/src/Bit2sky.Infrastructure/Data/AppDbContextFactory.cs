using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Bit2sky.Infrastructure.Data;

// Design-time factory so `dotnet ef migrations` runs without booting the API host.
// The connection string here is used ONLY by tooling to build the model; migration
// generation does not connect to a database. Override via BIT2SKY_DESIGN_DB if needed.
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("BIT2SKY_DESIGN_DB")
            ?? "Host=localhost;Database=bit2sky_design;Username=postgres;Password=postgres";

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(connectionString)
            .Options;

        return new AppDbContext(options);
    }
}
