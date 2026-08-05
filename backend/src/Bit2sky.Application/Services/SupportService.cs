using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Support tickets, own only (Section 7).
public class SupportService : ISupportService
{
    private readonly IAppDbContext _db;
    private readonly IRateLimitEnforcer _rateLimit;
    public SupportService(IAppDbContext db, IRateLimitEnforcer rateLimit) { _db = db; _rateLimit = rateLimit; }

    public async Task<SupportTicket> CreateAsync(Guid userId, CreateTicketRequest req, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("support_create", userId.ToString(), ct);
        var ticket = new SupportTicket
        {
            Id = Guid.NewGuid(), TicketNumber = "TKT" + DateTimeOffset.UtcNow.Ticks.ToString()[^9..],
            UserId = userId, Subject = req.Subject, Category = req.Category, Status = TicketStatus.Open,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        };
        ticket.Messages.Add(new SupportMessage { Id = Guid.NewGuid(), SenderUserId = userId, Body = req.Message });
        _db.Set<SupportTicket>().Add(ticket);
        await _db.SaveChangesAsync(ct);
        return ticket;
    }

    public async Task<IReadOnlyList<SupportTicket>> ListAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<SupportTicket>().AsNoTracking().Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt).ToListAsync(ct);

    public async Task<IReadOnlyList<SupportMessage>> GetMessagesAsync(Guid userId, Guid ticketId, CancellationToken ct = default)
    {
        await EnsureOwnedAsync(userId, ticketId, ct);
        return await _db.Set<SupportMessage>().AsNoTracking().Where(m => m.TicketId == ticketId)
            .OrderBy(m => m.CreatedAt).ToListAsync(ct);
    }

    public async Task<SupportMessage> AddMessageAsync(Guid userId, Guid ticketId, string body, CancellationToken ct = default)
    {
        await EnsureOwnedAsync(userId, ticketId, ct);
        var msg = new SupportMessage { Id = Guid.NewGuid(), TicketId = ticketId, SenderUserId = userId, Body = body };
        _db.Set<SupportMessage>().Add(msg);
        await _db.SaveChangesAsync(ct);
        return msg;
    }

    public async Task CloseAsync(Guid userId, Guid ticketId, CancellationToken ct = default)
    {
        var ticket = await EnsureOwnedAsync(userId, ticketId, ct);
        ticket.Status = TicketStatus.Closed;
        await _db.SaveChangesAsync(ct);
    }

    private async Task<SupportTicket> EnsureOwnedAsync(Guid userId, Guid ticketId, CancellationToken ct)
        => await _db.Set<SupportTicket>().FirstOrDefaultAsync(t => t.Id == ticketId && t.UserId == userId, ct)
           ?? throw new NotFoundAppException();
}
