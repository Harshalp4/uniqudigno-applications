using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Bit2sky.Infrastructure.Data.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> b)
    {
        b.ToTable("users", "core");
        b.HasKey(x => x.Id);

        // Mobile is optional (email/Google sign-up); unique when present.
        b.Property(x => x.Mobile).HasMaxLength(20);
        b.HasIndex(x => x.Mobile).IsUnique();

        b.Property(x => x.Name).HasMaxLength(150);
        b.Property(x => x.Email).HasMaxLength(255);
        b.HasIndex(x => x.Email).IsUnique();
        b.Property(x => x.AvatarUrl).HasMaxLength(500);

        b.Property(x => x.ReferralCode).HasMaxLength(20);
        b.HasIndex(x => x.ReferralCode).IsUnique();

        b.Property(x => x.IsActive).HasDefaultValue(true);
        b.Property(x => x.OtpAttemptCount).HasDefaultValue(0);
        b.Property(x => x.Admin2faEnabled).HasDefaultValue(false);
        b.Property(x => x.Admin2faBackupCodes).HasColumnType("text[]");
        b.Property(x => x.LastIpAddress).HasMaxLength(45);
        b.Property(x => x.FailedLoginCount).HasDefaultValue(0);
        b.Property(x => x.PasswordHash).HasMaxLength(255);
        b.Property(x => x.PiiEncrypted).HasDefaultValue(true);
        b.Property(x => x.CreatedAt).HasDefaultValueSql("now()");
        b.Property(x => x.UpdatedAt).HasDefaultValueSql("now()");

        b.HasOne(x => x.MembershipTier)
            .WithMany()
            .HasForeignKey(x => x.MembershipTierId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
