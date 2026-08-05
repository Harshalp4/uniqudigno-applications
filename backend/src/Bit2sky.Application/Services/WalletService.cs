using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Wallet, transactions, tier benefits (multipliers from DB). Own data only.
public class WalletService : IWalletService
{
    private readonly IAppDbContext _db;
    public WalletService(IAppDbContext db) => _db = db;

    public async Task<Wallet> GetWalletAsync(Guid userId, CancellationToken ct = default)
    {
        var wallet = await _db.Set<Wallet>().FirstOrDefaultAsync(w => w.UserId == userId, ct);
        if (wallet is null)
        {
            wallet = new Wallet { Id = Guid.NewGuid(), UserId = userId, UpdatedAt = DateTimeOffset.UtcNow };
            _db.Set<Wallet>().Add(wallet);
            await _db.SaveChangesAsync(ct);
        }
        return wallet;
    }

    public async Task<IReadOnlyList<WalletTransaction>> GetTransactionsAsync(Guid userId, CancellationToken ct = default)
    {
        var wallet = await GetWalletAsync(userId, ct);
        return await _db.Set<WalletTransaction>().AsNoTracking()
            .Where(t => t.WalletId == wallet.Id).OrderByDescending(t => t.CreatedAt).Take(200).ToListAsync(ct);
    }

    public async Task<IReadOnlyList<MembershipTier>> GetTierBenefitsAsync(CancellationToken ct = default)
        => await _db.Set<MembershipTier>().AsNoTracking().Where(t => t.IsActive).OrderBy(t => t.SortOrder).ToListAsync(ct);

    public async Task<Wallet> RedeemAsync(Guid userId, decimal amount, CancellationToken ct = default)
    {
        var wallet = await GetWalletAsync(userId, ct);
        if (amount <= 0 || amount > wallet.Balance)
            throw new ValidationAppException(new[] { new ApiError { Field = "amount", Message = "Invalid redemption amount" } });
        ApplyTransaction(wallet, WalletTransactionType.Debit, WalletTransactionReason.Redemption, amount, null);
        await _db.SaveChangesAsync(ct);
        return wallet;
    }

    public async Task AdminAdjustAsync(Guid targetUserId, decimal amount, string reason, Guid adminId, CancellationToken ct = default)
    {
        var wallet = await GetWalletAsync(targetUserId, ct);
        var type = amount >= 0 ? WalletTransactionType.Credit : WalletTransactionType.Debit;
        ApplyTransaction(wallet, type, WalletTransactionReason.Adjustment, Math.Abs(amount), reason, adminId);
        await _db.SaveChangesAsync(ct);
    }

    private void ApplyTransaction(Wallet wallet, WalletTransactionType type, WalletTransactionReason reason,
        decimal amount, string? note, Guid? adminId = null)
    {
        wallet.Balance += type == WalletTransactionType.Credit ? amount : -amount;
        if (type == WalletTransactionType.Credit) wallet.LifetimeEarned += amount;
        wallet.UpdatedAt = DateTimeOffset.UtcNow;
        _db.Set<WalletTransaction>().Add(new WalletTransaction
        {
            Id = Guid.NewGuid(), WalletId = wallet.Id, Type = type, Reason = reason,
            Amount = amount, BalanceAfter = wallet.Balance, Note = note, AdjustedByAdminId = adminId,
        });
    }
}
