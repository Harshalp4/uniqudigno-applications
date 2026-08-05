using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Cart with ownership enforcement (Section 7). Wallet cap read from config (not hardcoded).
public class CartService : ICartService
{
    private const string WalletCapPercentKey = "wallet_redeem_cap_percent";
    private const decimal DefaultWalletCapPercent = 10m;
    private const string GroupTiersKey = "group_discount_tiers";
    private const string DefaultGroupTiers = "0,15,20,25"; // % off/person at 1..4+ members

    private readonly IAppDbContext _db;

    public CartService(IAppDbContext db) => _db = db;

    public async Task<CartSummary> GetCartAsync(Guid userId, CancellationToken ct = default)
        => await SummarizeAsync(await GetOrCreateAsync(userId, ct), ct);

    public async Task<CartSummary> AddItemAsync(Guid userId, AddCartItemRequest req, CancellationToken ct = default)
    {
        var cart = await GetOrCreateAsync(userId, ct);

        // Validate family-member ownership when the item is for a dependent.
        if (req.FamilyMemberId is { } fmId &&
            !await _db.Set<FamilyMember>().AnyAsync(f => f.Id == fmId && f.UserId == userId, ct))
            throw new ForbiddenAppException();

        string name; decimal mrp, price;
        if (req.PackageId is { } pid)
        {
            var pkg = await _db.Set<Package>().FirstOrDefaultAsync(p => p.Id == pid && p.IsActive, ct)
                ?? throw new NotFoundAppException();
            (name, mrp, price) = (pkg.Name, pkg.Mrp, pkg.Price);
        }
        else if (req.TestId is { } tid)
        {
            var test = await _db.Set<Test>().FirstOrDefaultAsync(t => t.Id == tid && t.IsActive, ct)
                ?? throw new NotFoundAppException();
            (name, mrp, price) = (test.Name, test.Mrp, test.Price);
        }
        else throw new ValidationAppException(new[] { new ApiError { Field = "item", Message = "TestId or PackageId required" } });

        // Add via the DbSet (explicit Added state) — adding through the tracked
        // cart.Items navigation with a pre-set Id makes EF emit an UPDATE instead
        // of an INSERT, which fails as a phantom "0 rows affected".
        var item = new CartItem
        {
            Id = Guid.NewGuid(),
            CartId = cart.Id,
            TestId = req.TestId,
            PackageId = req.PackageId,
            FamilyMemberId = req.FamilyMemberId,
            ItemName = name,
            Mrp = mrp,
            Price = price,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        // Add via the DbSet only — EF's relationship fixup adds it to cart.Items,
        // so also calling cart.Items.Add() would duplicate it in the response.
        _db.Set<CartItem>().Add(item);
        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        return await SummarizeAsync(cart, ct);
    }

    public async Task<CartSummary> RemoveItemAsync(Guid userId, Guid itemId, CancellationToken ct = default)
    {
        var cart = await GetOrCreateAsync(userId, ct);
        var item = cart.Items.FirstOrDefault(i => i.Id == itemId)
            ?? throw new NotFoundAppException(); // item not in the caller's cart ⇒ 404 (no enumeration)
        cart.Items.Remove(item);
        _db.Set<CartItem>().Remove(item);
        await _db.SaveChangesAsync(ct);
        return await SummarizeAsync(cart, ct);
    }

    public async Task<CartSummary> ApplyWalletPointsAsync(Guid userId, decimal points, CancellationToken ct = default)
    {
        var cart = await GetOrCreateAsync(userId, ct);
        var itemsTotal = cart.Items.Sum(i => i.Price);

        if (points < 0)
            throw new ValidationAppException(new[] { new ApiError { Field = "points", Message = "Invalid points" } });

        // Server-authoritative clamp: requested points are capped to the
        // redemption cap AND the wallet's actual balance, so the client can
        // simply send its full balance ("use my wallet") and the response's
        // walletApplied reflects what was really applied. The booking flow
        // re-checks the balance and performs the debit atomically at checkout.
        var capPercent = await GetDecimalConfigAsync(WalletCapPercentKey, DefaultWalletCapPercent, ct);
        var maxRedeemable = itemsTotal * capPercent / 100m;
        var balance = await _db.Set<Wallet>().Where(w => w.UserId == userId)
            .Select(w => (decimal?)w.Balance).FirstOrDefaultAsync(ct) ?? 0m;

        cart.WalletPointsApplied = Math.Min(points, Math.Min(maxRedeemable, balance));
        await _db.SaveChangesAsync(ct);
        return await SummarizeAsync(cart, ct);
    }

    public async Task<CartSummary> ApplyCouponAsync(Guid userId, string code, CancellationToken ct = default)
    {
        var cart = await GetOrCreateAsync(userId, ct);
        var normalized = code.Trim().ToUpperInvariant();
        var coupon = await _db.Set<Coupon>().AsNoTracking()
            .FirstOrDefaultAsync(c => c.Code == normalized, ct);
        var itemsTotal = cart.Items.Sum(i => i.Price);
        var (valid, _, message) = ValidateCoupon(coupon, itemsTotal);
        if (!valid || coupon is null)
            throw new ValidationAppException(new[] { new ApiError { Field = "coupon", Message = message } });
        // Per-user limit: count this user's bookings that already used the code.
        if (coupon.PerUserLimit > 0)
        {
            var used = await _db.Set<Booking>()
                .CountAsync(b => b.UserId == userId && b.CouponId == coupon.Id, ct);
            if (used >= coupon.PerUserLimit)
                throw new ValidationAppException(new[] { new ApiError
                    { Field = "coupon", Message = "You have already used this coupon" } });
        }
        cart.CouponId = coupon.Id;
        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        return await SummarizeAsync(cart, ct);
    }

    public async Task<CartSummary> RemoveCouponAsync(Guid userId, CancellationToken ct = default)
    {
        var cart = await GetOrCreateAsync(userId, ct);
        cart.CouponId = null;
        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        return await SummarizeAsync(cart, ct);
    }

    /// Shared cheap validation + discount math (mirrors CouponService rules).
    internal static (bool Valid, decimal Discount, string Message) ValidateCoupon(Coupon? coupon, decimal orderValue)
    {
        var now = DateTimeOffset.UtcNow;
        if (coupon is null || !coupon.IsActive) return (false, 0, "Invalid coupon");
        if (coupon.ValidFrom is { } vf && vf > now || coupon.ValidUntil is { } vu && vu < now)
            return (false, 0, "Coupon expired");
        if (coupon.MinOrderValue is { } min && orderValue < min)
            return (false, 0, $"Minimum order value is ₹{min:0}");
        if (coupon.TotalUsageLimit is { } limit && coupon.UsedCount >= limit)
            return (false, 0, "Coupon usage limit reached");
        var discount = coupon.Type == CouponType.Percentage
            ? orderValue * coupon.Value / 100m
            : coupon.Value;
        if (coupon.MaxDiscount is { } cap) discount = Math.Min(discount, cap);
        return (true, Math.Round(Math.Min(discount, orderValue), 2), "OK");
    }

    private async Task<Cart> GetOrCreateAsync(Guid userId, CancellationToken ct)
    {
        var cart = await _db.Set<Cart>().Include(c => c.Items)
            .FirstOrDefaultAsync(c => c.UserId == userId, ct);
        if (cart is null)
        {
            cart = new Cart { Id = Guid.NewGuid(), UserId = userId, UpdatedAt = DateTimeOffset.UtcNow };
            _db.Set<Cart>().Add(cart);
            await _db.SaveChangesAsync(ct);
        }
        return cart;
    }

    private async Task<decimal> GetDecimalConfigAsync(string key, decimal fallback, CancellationToken ct)
    {
        var raw = await _db.Set<AppConfig>().Where(c => c.Key == key).Select(c => c.Value).FirstOrDefaultAsync(ct);
        return decimal.TryParse(raw, out var v) ? v : fallback;
    }

    private async Task<CartSummary> SummarizeAsync(Cart cart, CancellationToken ct)
    {
        var itemsTotal = cart.Items.Sum(i => i.Price);
        var discount = cart.Items.Sum(i => i.Mrp - i.Price);

        // Coupon: re-validated on every summary; a coupon that stopped being
        // valid (expired, min-order no longer met after item removal) is
        // silently detached so totals never lie.
        string? couponCode = null;
        var couponDiscount = 0m;
        if (cart.CouponId is { } couponId)
        {
            var coupon = await _db.Set<Coupon>().AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == couponId, ct);
            var (valid, amount, _) = ValidateCoupon(coupon, itemsTotal);
            if (valid && coupon is not null)
            {
                couponCode = coupon.Code;
                couponDiscount = amount;
            }
            else
            {
                cart.CouponId = null;
                await _db.SaveChangesAsync(ct);
            }
        }

        // Family/group pricing: the same package booked for N people in one
        // order gets the configured per-person tier discount (Healthians-style).
        var groupDiscount = await ComputeGroupDiscountAsync(cart, ct);

        var payable = Math.Max(0,
            itemsTotal - couponDiscount - groupDiscount - cart.WalletPointsApplied);
        var lines = cart.Items
            .Select(i => new CartLine(i.Id, i.TestId, i.PackageId, i.CustomPackageId,
                i.FamilyMemberId, i.ItemName, i.Mrp, i.Price))
            .ToList();
        return new CartSummary(cart.Id, lines, itemsTotal, discount,
            cart.WalletPointsApplied, payable, couponCode, couponDiscount,
            groupDiscount);
    }

    /// % off per person for a same-package multi-member booking, by member
    /// count (index 0 = 1 member). Config CSV, e.g. "0,15,20,25".
    internal static decimal[] ParseTiers(string? raw)
    {
        var parts = (raw ?? DefaultGroupTiers).Split(',');
        var tiers = new List<decimal>();
        foreach (var part in parts)
            if (decimal.TryParse(part.Trim(), out var v)) tiers.Add(Math.Clamp(v, 0, 90));
        return tiers.Count == 0 ? new[] { 0m } : tiers.ToArray();
    }

    internal static decimal GroupDiscountFor(
        IEnumerable<(Guid? PackageId, Guid? FamilyMemberId, decimal Price)> items,
        decimal[] tiers)
    {
        var total = 0m;
        foreach (var g in items.Where(i => i.PackageId != null).GroupBy(i => i.PackageId))
        {
            var members = g.Select(i => i.FamilyMemberId).Distinct().Count();
            var count = Math.Min(g.Count(), members == 0 ? 1 : members);
            if (count < 2) continue;
            var pct = tiers[Math.Min(count, tiers.Length) - 1];
            if (pct <= 0) continue;
            total += Math.Round(g.Sum(i => i.Price) * pct / 100m, 2);
        }
        return total;
    }

    private async Task<decimal> ComputeGroupDiscountAsync(Cart cart, CancellationToken ct)
    {
        if (!cart.Items.Any(i => i.PackageId != null)) return 0m;
        var raw = await _db.Set<AppConfig>().Where(c => c.Key == GroupTiersKey)
            .Select(c => c.Value).FirstOrDefaultAsync(ct);
        return GroupDiscountFor(
            cart.Items.Select(i => (i.PackageId, i.FamilyMemberId, i.Price)),
            ParseTiers(raw));
    }
}
