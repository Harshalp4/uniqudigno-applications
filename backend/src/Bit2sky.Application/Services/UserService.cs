using Bit2sky.Application.Abstractions;
using Bit2sky.Application.DTOs;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Users + family + addresses with ownership; admin views with PII masking (Section 4B/4E).
public class UserService : IUserService
{
    private readonly IAppDbContext _db;
    private readonly IDataMaskingService _mask;

    public UserService(IAppDbContext db, IDataMaskingService mask)
    {
        _db = db;
        _mask = mask;
    }

    public async Task<User> GetMeAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<User>().FirstOrDefaultAsync(u => u.Id == userId && !u.IsDeleted, ct)
           ?? throw new NotFoundAppException();

    // Explicit field allowlist — mass-assignment protection (Section 4B).
    public async Task<User> UpdateMeAsync(Guid userId, UpdateMeRequest req, CancellationToken ct = default)
    {
        var user = await GetMeAsync(userId, ct);
        if (req.Name is not null) user.Name = req.Name;
        if (req.Email is not null) user.Email = req.Email;
        if (req.DateOfBirth is not null) user.DateOfBirth = req.DateOfBirth;
        if (req.Gender is not null) user.Gender = req.Gender;
        if (req.Mobile is not null)
        {
            var taken = await _db.Set<User>().AnyAsync(
                u => u.Mobile == req.Mobile && u.Id != userId && !u.IsDeleted, ct);
            if (taken) throw new ConflictAppException("This mobile number is already registered.");
            user.Mobile = req.Mobile;
        }
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        return user;
    }

    public async Task<DashboardDto> GetDashboardAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await GetMeAsync(userId, ct);
        var upcoming = await _db.Set<Booking>().CountAsync(b =>
            b.UserId == userId && b.Status == BookingStatus.Confirmed && b.ScheduledDate >= DateOnly.FromDateTime(DateTime.UtcNow), ct);
        var reportsReady = await _db.Set<LabReport>().CountAsync(r => r.UserId == userId && r.Status == ReportStatus.Ready, ct);
        var score = await _db.Set<HealthScore>().Where(h => h.UserId == userId)
            .OrderByDescending(h => h.CalculatedAt).Select(h => (int?)h.Score).FirstOrDefaultAsync(ct);
        var wallet = await _db.Set<Wallet>().Where(w => w.UserId == userId).Select(w => w.Balance).FirstOrDefaultAsync(ct);
        return new DashboardDto(user.Name, upcoming, reportsReady, score, wallet);
    }

    // ── Family (ownership-enforced) ─────────────────────────────────────────────
    public async Task<IReadOnlyList<FamilyMember>> GetFamilyAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<FamilyMember>().Where(f => f.UserId == userId && !f.IsDeleted).ToListAsync(ct);

    public async Task<FamilyMember> AddFamilyAsync(Guid userId, FamilyMemberRequest req, CancellationToken ct = default)
    {
        var member = new FamilyMember
        {
            Id = Guid.NewGuid(), UserId = userId, Name = req.Name, Relationship = req.Relationship,
            DateOfBirth = req.DateOfBirth, Gender = req.Gender, BloodGroup = req.BloodGroup, Mobile = req.Mobile,
        };
        _db.Set<FamilyMember>().Add(member);
        await _db.SaveChangesAsync(ct);
        return member;
    }

    public async Task<FamilyMember> UpdateFamilyAsync(Guid userId, Guid id, FamilyMemberRequest req, CancellationToken ct = default)
    {
        var member = await OwnedFamilyAsync(userId, id, ct);
        member.Name = req.Name; member.Relationship = req.Relationship; member.DateOfBirth = req.DateOfBirth;
        member.Gender = req.Gender; member.BloodGroup = req.BloodGroup; member.Mobile = req.Mobile;
        await _db.SaveChangesAsync(ct);
        return member;
    }

    public async Task DeleteFamilyAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var member = await OwnedFamilyAsync(userId, id, ct);
        member.IsDeleted = true;
        await _db.SaveChangesAsync(ct);
    }

    // ── Addresses (ownership-enforced) ──────────────────────────────────────────
    public async Task<IReadOnlyList<Address>> GetAddressesAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<Address>().Where(a => a.UserId == userId && !a.IsDeleted).ToListAsync(ct);

    public async Task<Address> AddAddressAsync(Guid userId, AddressRequest req, CancellationToken ct = default)
    {
        var address = new Address
        {
            Id = Guid.NewGuid(), UserId = userId, Type = req.Type, Line1 = req.Line1, Line2 = req.Line2,
            Landmark = req.Landmark, City = req.City, State = req.State, Pincode = req.Pincode,
            Latitude = req.Latitude, Longitude = req.Longitude,
        };
        _db.Set<Address>().Add(address);
        await _db.SaveChangesAsync(ct);
        return address;
    }

    public async Task<Address> UpdateAddressAsync(Guid userId, Guid id, AddressRequest req, CancellationToken ct = default)
    {
        var address = await OwnedAddressAsync(userId, id, ct);
        address.Type = req.Type; address.Line1 = req.Line1; address.Line2 = req.Line2; address.Landmark = req.Landmark;
        address.City = req.City; address.State = req.State; address.Pincode = req.Pincode;
        address.Latitude = req.Latitude; address.Longitude = req.Longitude;
        await _db.SaveChangesAsync(ct);
        return address;
    }

    public async Task DeleteAddressAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var address = await OwnedAddressAsync(userId, id, ct);
        address.IsDeleted = true;
        await _db.SaveChangesAsync(ct);
    }

    public async Task SetDefaultAddressAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var addresses = await _db.Set<Address>().Where(a => a.UserId == userId && !a.IsDeleted).ToListAsync(ct);
        if (addresses.All(a => a.Id != id)) throw new NotFoundAppException();
        foreach (var a in addresses) a.IsDefault = a.Id == id;
        await _db.SaveChangesAsync(ct);
    }

    // ── Admin ───────────────────────────────────────────────────────────────────
    public async Task<PagedResult<object>> AdminListAsync(bool includePii, PageRequest page, CancellationToken ct = default)
    {
        var query = _db.Set<User>().AsNoTracking().Where(u => !u.IsDeleted);
        var total = await query.CountAsync(ct);
        var users = await query.OrderByDescending(u => u.CreatedAt).Skip(page.Skip).Take(page.PageSize).ToListAsync(ct);

        var items = users.Select(u => includePii
            ? (object)new AdminUserDto(u.Id, u.Name, u.Mobile, u.Email, u.DateOfBirth, u.IsActive, u.CreatedAt)
            : new SupportUserDto(u.Id, u.Name, _mask.MaskPhone(u.Mobile), u.IsActive)).ToList();

        return new PagedResult<object> { Items = items, Total = total, Page = page.Page, PageSize = page.PageSize };
    }

    public async Task DeactivateAsync(Guid userId, bool active, CancellationToken ct = default)
    {
        var user = await _db.Set<User>().FirstOrDefaultAsync(u => u.Id == userId, ct) ?? throw new NotFoundAppException();
        user.IsActive = active;
        await _db.SaveChangesAsync(ct);
    }

    public async Task SoftDeleteAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _db.Set<User>().FirstOrDefaultAsync(u => u.Id == userId, ct) ?? throw new NotFoundAppException();
        user.IsDeleted = true;
        user.Name = null; user.Email = null; user.DateOfBirth = null; // PHI anonymized
        await _db.SaveChangesAsync(ct);
    }

    private async Task<FamilyMember> OwnedFamilyAsync(Guid userId, Guid id, CancellationToken ct)
        => await _db.Set<FamilyMember>().FirstOrDefaultAsync(f => f.Id == id && f.UserId == userId && !f.IsDeleted, ct)
           ?? throw new NotFoundAppException();

    private async Task<Address> OwnedAddressAsync(Guid userId, Guid id, CancellationToken ct)
        => await _db.Set<Address>().FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId && !a.IsDeleted, ct)
           ?? throw new NotFoundAppException();
}
