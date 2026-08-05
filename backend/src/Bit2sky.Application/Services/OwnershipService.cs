using System.Linq.Expressions;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Section 4B IDOR prevention + Section 3C #4/#5 role-scoped access.
public class OwnershipService : IOwnershipService
{
    private const string AdminRole = "admin";
    private const string SuperAdminRole = "super_admin";
    private readonly IAppDbContext _db;

    public OwnershipService(IAppDbContext db) => _db = db;

    private static bool IsAdmin(string role) => role is AdminRole or SuperAdminRole or "operations" or "support" or "lab" or "finance";

    public async Task<bool> CanAccessBookingAsync(Guid currentUserId, string role, Guid? partnerId, Guid bookingId, CancellationToken ct = default)
    {
        var booking = await _db.Set<Booking>().AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == bookingId, ct);
        if (booking is null) return false;

        return role switch
        {
            SuperAdminRole or AdminRole or "operations" or "lab" or "finance" or "support" => true,
            "partner" => partnerId.HasValue && booking.PartnerId == partnerId,
            // Booking.TechnicianId stores Technician.Id, not the user id — resolve via UserId.
            "technician" => booking.TechnicianId != null && await _db.Set<Technician>().AsNoTracking()
                .AnyAsync(t => t.Id == booking.TechnicianId && t.UserId == currentUserId, ct),
            _ => booking.UserId == currentUserId,
        };
    }

    public async Task<bool> CanAccessReportAsync(Guid currentUserId, Guid reportId, CancellationToken ct = default)
    {
        var report = await _db.Set<LabReport>().AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == reportId, ct);
        if (report is null) return false;
        if (report.UserId == currentUserId) return true;

        // Family-member reports: the report's family member must belong to the caller.
        if (report.FamilyMemberId is { } fmId)
            return await _db.Set<FamilyMember>().AsNoTracking()
                .AnyAsync(fm => fm.Id == fmId && fm.UserId == currentUserId, ct);

        return false;
    }

    // Generic ownership check for dependents carrying a UserId property.
    public async Task<bool> OwnsAsync<TEntity>(Guid currentUserId, Guid entityId, CancellationToken ct = default)
        where TEntity : class
    {
        var entity = typeof(TEntity);
        if (entity.GetProperty("UserId") is null || entity.GetProperty("Id") is null)
            throw new InvalidOperationException($"{entity.Name} has no Id/UserId for ownership checks.");

        var param = Expression.Parameter(entity, "e");
        var idEq = Expression.Equal(Expression.Property(param, "Id"), Expression.Constant(entityId));
        var userEq = Expression.Equal(Expression.Property(param, "UserId"), Expression.Constant(currentUserId));
        var predicate = Expression.Lambda<Func<TEntity, bool>>(Expression.AndAlso(idEq, userEq), param);

        return await _db.Set<TEntity>().AsNoTracking().AnyAsync(predicate, ct);
    }
}
