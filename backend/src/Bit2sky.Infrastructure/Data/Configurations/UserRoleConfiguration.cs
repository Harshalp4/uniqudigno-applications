using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Bit2sky.Infrastructure.Data.Configurations;

public class UserRoleConfiguration : IEntityTypeConfiguration<UserRole>
{
    public void Configure(EntityTypeBuilder<UserRole> b)
    {
        b.ToTable("user_roles", "admin");

        b.HasKey(x => x.Id);
        b.HasIndex(x => new { x.UserId, x.RoleId }).IsUnique();

        b.Property(x => x.AssignedAt).HasDefaultValueSql("now()");

        b.HasOne(x => x.User)
            .WithMany(u => u.UserRoles)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        b.HasOne(x => x.Role)
            .WithMany(r => r.UserRoles)
            .HasForeignKey(x => x.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        // assigned_by → core.users(id), no inverse navigation
        b.HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.AssignedBy)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
