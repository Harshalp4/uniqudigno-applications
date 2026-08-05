using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Bit2sky.Infrastructure.Data.Configurations;

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> b)
    {
        b.ToTable("refresh_tokens", "core");
        b.HasKey(x => x.Id);

        b.Property(x => x.TokenHash).HasMaxLength(128).IsRequired();
        b.HasIndex(x => x.TokenHash).IsUnique();

        b.Property(x => x.DeviceId).HasMaxLength(128).IsRequired();
        b.Property(x => x.ReplacedByTokenHash).HasMaxLength(128);
        b.Property(x => x.TokenFamily).IsRequired();
        b.Property(x => x.IsTheftDetected).HasDefaultValue(false);
        b.Property(x => x.CreatedAt).HasDefaultValueSql("now()");

        b.HasIndex(x => x.TokenFamily);

        b.HasOne(x => x.User)
            .WithMany(u => u.RefreshTokens)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
