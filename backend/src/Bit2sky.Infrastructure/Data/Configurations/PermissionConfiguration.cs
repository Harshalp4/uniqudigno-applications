using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Bit2sky.Infrastructure.Data.Configurations;

public class PermissionConfiguration : IEntityTypeConfiguration<Permission>
{
    public void Configure(EntityTypeBuilder<Permission> b)
    {
        b.ToTable("permissions", "admin", t => t.HasCheckConstraint(
            "ck_permissions_action",
            "action IN ('view','create','update','delete','export','approve','assign','manage','broadcast')"));

        b.HasKey(x => x.Id);

        b.Property(x => x.Code).HasMaxLength(100).IsRequired();
        b.HasIndex(x => x.Code).IsUnique();

        b.Property(x => x.Module).HasMaxLength(50).IsRequired();

        b.Property(x => x.Action)
            .HasMaxLength(30)
            .IsRequired()
            .HasConversion(
                v => v.ToString().ToLowerInvariant(),
                v => Enum.Parse<PermissionAction>(v, ignoreCase: true));

        b.Property(x => x.Description).IsRequired();

        b.Property(x => x.CreatedAt).HasDefaultValueSql("now()");
    }
}
