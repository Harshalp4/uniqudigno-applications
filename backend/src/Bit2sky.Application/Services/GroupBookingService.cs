using System.Security.Cryptography;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Group bookings with shareable code (Section 7). Feature flag checked at controller.
public class GroupBookingService : IGroupBookingService
{
    private static readonly TimeSpan DefaultExpiry = TimeSpan.FromDays(7);
    private readonly IAppDbContext _db;
    public GroupBookingService(IAppDbContext db) => _db = db;

    public async Task<GroupBooking> CreateAsync(Guid userId, GroupBookingRequest req, CancellationToken ct = default)
    {
        var group = new GroupBooking
        {
            Id = Guid.NewGuid(), Code = NewCode(), CreatedByUserId = userId,
            PackageId = req.PackageId, TestId = req.TestId, MinMembers = req.MinMembers, MaxMembers = req.MaxMembers,
            DiscountPercent = req.DiscountPercent, Status = GroupBookingStatus.Open,
            ExpiresAt = DateTimeOffset.UtcNow.Add(DefaultExpiry),
        };
        group.Members.Add(new GroupBookingMember { Id = Guid.NewGuid(), UserId = userId, JoinedAt = DateTimeOffset.UtcNow });
        _db.Set<GroupBooking>().Add(group);
        await _db.SaveChangesAsync(ct);
        return group;
    }

    public async Task<GroupBooking> GetByCodeAsync(string code, CancellationToken ct = default)
        => await _db.Set<GroupBooking>().Include(g => g.Members).AsNoTracking()
            .FirstOrDefaultAsync(g => g.Code == code, ct) ?? throw new NotFoundAppException();

    public async Task JoinAsync(Guid userId, string code, CancellationToken ct = default)
    {
        var group = await _db.Set<GroupBooking>().Include(g => g.Members).FirstOrDefaultAsync(g => g.Code == code, ct)
            ?? throw new NotFoundAppException();
        if (group.Status != GroupBookingStatus.Open || group.ExpiresAt < DateTimeOffset.UtcNow)
            throw new ConflictAppException("Group is closed");
        if (group.Members.Count >= group.MaxMembers)
            throw new ConflictAppException("Group is full");
        if (group.Members.Any(m => m.UserId == userId)) return;
        group.Members.Add(new GroupBookingMember { Id = Guid.NewGuid(), UserId = userId, JoinedAt = DateTimeOffset.UtcNow });
        await _db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<GroupBooking>> MyGroupsAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<GroupBooking>().Include(g => g.Members).AsNoTracking()
            .Where(g => g.Members.Any(m => m.UserId == userId)).ToListAsync(ct);

    public async Task LeaveAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var group = await _db.Set<GroupBooking>().Include(g => g.Members).FirstOrDefaultAsync(g => g.Id == id, ct)
            ?? throw new NotFoundAppException();
        var member = group.Members.FirstOrDefault(m => m.UserId == userId) ?? throw new NotFoundAppException();
        group.Members.Remove(member);
        _db.Set<GroupBookingMember>().Remove(member);
        await _db.SaveChangesAsync(ct);
    }

    private static string NewCode() => "GRP" + Convert.ToHexString(RandomNumberGenerator.GetBytes(3));
}
