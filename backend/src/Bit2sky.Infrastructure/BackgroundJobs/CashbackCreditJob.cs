using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.BackgroundJobs;

// Credits pending cashback past its credit date into the user's wallet (Section 16).
public class CashbackCreditJob
{
    private readonly IAppDbContext _db;
    public CashbackCreditJob(IAppDbContext db) => _db = db;

    public async Task ExecuteAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var due = await _db.Set<Cashback>()
            .Where(c => c.Status == CashbackStatus.Pending && c.CreditAt != null && c.CreditAt <= now)
            .ToListAsync(ct);

        foreach (var cashback in due)
        {
            var wallet = await _db.Set<Wallet>().FirstOrDefaultAsync(w => w.UserId == cashback.UserId, ct);
            if (wallet is null)
            {
                wallet = new Wallet { Id = Guid.NewGuid(), UserId = cashback.UserId, UpdatedAt = now };
                _db.Set<Wallet>().Add(wallet);
            }
            wallet.Balance += cashback.Amount;
            wallet.LifetimeEarned += cashback.Amount;
            _db.Set<WalletTransaction>().Add(new WalletTransaction
            {
                Id = Guid.NewGuid(), WalletId = wallet.Id, Type = WalletTransactionType.Credit,
                Reason = WalletTransactionReason.Cashback, Amount = cashback.Amount,
                BalanceAfter = wallet.Balance, ReferenceId = cashback.Id.ToString(),
            });
            cashback.Status = CashbackStatus.Credited;
        }
        await _db.SaveChangesAsync(ct);
    }
}
