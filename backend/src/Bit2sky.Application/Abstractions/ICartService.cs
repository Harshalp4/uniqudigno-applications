using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public record AddCartItemRequest(Guid? TestId, Guid? PackageId, Guid? FamilyMemberId);
// Flat line DTO — no Cart back-reference, so the response can't serialize into a
// CartItem -> Cart -> Items cycle.
public record CartLine(Guid Id, Guid? TestId, Guid? PackageId, Guid? CustomPackageId,
    Guid? FamilyMemberId, string ItemName, decimal Mrp, decimal Price);
public record CartSummary(Guid CartId, IReadOnlyList<CartLine> Items, decimal ItemsTotal, decimal Discount, decimal WalletApplied, decimal Payable, string? CouponCode = null, decimal CouponDiscount = 0, decimal GroupDiscount = 0);

public interface ICartService
{
    Task<CartSummary> GetCartAsync(Guid userId, CancellationToken ct = default);
    Task<CartSummary> AddItemAsync(Guid userId, AddCartItemRequest req, CancellationToken ct = default);
    Task<CartSummary> RemoveItemAsync(Guid userId, Guid itemId, CancellationToken ct = default);
    Task<CartSummary> ApplyWalletPointsAsync(Guid userId, decimal points, CancellationToken ct = default);
    Task<CartSummary> ApplyCouponAsync(Guid userId, string code, CancellationToken ct = default);
    Task<CartSummary> RemoveCouponAsync(Guid userId, CancellationToken ct = default);
}
