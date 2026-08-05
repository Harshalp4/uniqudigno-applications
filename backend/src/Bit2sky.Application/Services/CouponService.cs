using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Coupon validation only — no side effects (Section 7). Expiry, limits, min-order checks.
public class CouponService : ICouponService
{
    private readonly IAppDbContext _db;
    public CouponService(IAppDbContext db) => _db = db;

    public async Task<CouponValidationResult> ValidateAsync(Guid userId, string code, decimal orderValue, CancellationToken ct = default)
    {
        var coupon = await _db.Set<Coupon>().AsNoTracking().FirstOrDefaultAsync(c => c.Code == code, ct);
        var now = DateTimeOffset.UtcNow;

        if (coupon is null || !coupon.IsActive)
            return new CouponValidationResult(false, 0, "Invalid coupon");
        if (coupon.ValidFrom is { } vf && vf > now || coupon.ValidUntil is { } vu && vu < now)
            return new CouponValidationResult(false, 0, "Coupon expired");
        if (coupon.MinOrderValue is { } min && orderValue < min)
            return new CouponValidationResult(false, 0, $"Minimum order value is {min}");
        if (coupon.TotalUsageLimit is { } limit && coupon.UsedCount >= limit)
            return new CouponValidationResult(false, 0, "Coupon usage limit reached");

        var discount = coupon.Type == CouponType.Percentage
            ? orderValue * coupon.Value / 100m
            : coupon.Value;
        if (coupon.MaxDiscount is { } cap) discount = Math.Min(discount, cap);

        return new CouponValidationResult(true, Math.Round(discount, 2), "Coupon applied");
    }

    // ── Admin CRUD (Section 11) ──────────────────────────────────────────────
    public async Task<IReadOnlyList<Coupon>> ListAsync(CancellationToken ct = default)
        => await _db.Set<Coupon>().AsNoTracking().OrderByDescending(c => c.CreatedAt).ToListAsync(ct);

    public async Task<Coupon> CreateAsync(CouponInput input, CancellationToken ct = default)
    {
        var code = input.Code.Trim().ToUpperInvariant();
        if (await _db.Set<Coupon>().AnyAsync(c => c.Code == code, ct))
            throw new ConflictAppException("A coupon with this code already exists.");

        var coupon = new Coupon { Id = Guid.NewGuid(), Code = code };
        Apply(coupon, input);
        _db.Set<Coupon>().Add(coupon);
        await _db.SaveChangesAsync(ct);
        return coupon;
    }

    public async Task<Coupon> UpdateAsync(Guid id, CouponInput input, CancellationToken ct = default)
    {
        var coupon = await _db.Set<Coupon>().FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new NotFoundAppException();

        var code = input.Code.Trim().ToUpperInvariant();
        if (code != coupon.Code && await _db.Set<Coupon>().AnyAsync(c => c.Code == code && c.Id != id, ct))
            throw new ConflictAppException("A coupon with this code already exists.");

        coupon.Code = code;
        Apply(coupon, input);
        await _db.SaveChangesAsync(ct);
        return coupon;
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var coupon = await _db.Set<Coupon>().FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new NotFoundAppException();
        _db.Set<Coupon>().Remove(coupon);
        await _db.SaveChangesAsync(ct);
    }

    private static void Apply(Coupon c, CouponInput i)
    {
        c.Description = i.Description;
        c.Type = Enum.TryParse<CouponType>(i.Type, ignoreCase: true, out var t) ? t : CouponType.Flat;
        c.Value = i.Value;
        c.MaxDiscount = i.MaxDiscount;
        c.MinOrderValue = i.MinOrderValue;
        c.TotalUsageLimit = i.TotalUsageLimit;
        c.PerUserLimit = i.PerUserLimit < 1 ? 1 : i.PerUserLimit;
        c.ValidFrom = i.ValidFrom;
        c.ValidUntil = i.ValidUntil;
        c.IsActive = i.IsActive;
    }
}
