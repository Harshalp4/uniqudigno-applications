using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Admin support queue (Section 11). Agent replies set IsFromAgent and move the
// ticket to InProgress; customer contact is masked in the list projection.
public class AdminSupportService : IAdminSupportService
{
    private readonly IAppDbContext _db;
    private readonly IDataMaskingService _mask;

    public AdminSupportService(IAppDbContext db, IDataMaskingService mask)
    {
        _db = db;
        _mask = mask;
    }

    public async Task<IReadOnlyList<AdminTicketDto>> ListAsync(string? status, CancellationToken ct = default)
    {
        var query = from t in _db.Set<SupportTicket>().AsNoTracking()
                    join u in _db.Set<User>().AsNoTracking() on t.UserId equals u.Id
                    select new { t, u.Mobile };

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<TicketStatus>(status, true, out var s))
            query = query.Where(x => x.t.Status == s);

        var rows = await query.OrderByDescending(x => x.t.UpdatedAt).Take(300).ToListAsync(ct);
        return rows.Select(x => new AdminTicketDto(
            x.t.Id, x.t.TicketNumber, _mask.MaskPhone(x.Mobile), x.t.Subject, x.t.Category,
            x.t.Status.ToString(), x.t.Priority.ToString(), x.t.CreatedAt, x.t.UpdatedAt)).ToList();
    }

    public async Task<IReadOnlyList<SupportMessage>> GetMessagesAsync(Guid ticketId, CancellationToken ct = default)
    {
        _ = await _db.Set<SupportTicket>().AsNoTracking().FirstOrDefaultAsync(t => t.Id == ticketId, ct)
            ?? throw new NotFoundAppException();
        return await _db.Set<SupportMessage>().AsNoTracking().Where(m => m.TicketId == ticketId)
            .OrderBy(m => m.CreatedAt).ToListAsync(ct);
    }

    public async Task<SupportMessage> ReplyAsync(Guid ticketId, Guid adminId, string body, CancellationToken ct = default)
    {
        var ticket = await _db.Set<SupportTicket>().FirstOrDefaultAsync(t => t.Id == ticketId, ct)
            ?? throw new NotFoundAppException();

        var msg = new SupportMessage
        {
            Id = Guid.NewGuid(), TicketId = ticketId, SenderUserId = adminId,
            IsFromAgent = true, Body = body, CreatedAt = DateTimeOffset.UtcNow,
        };
        _db.Set<SupportMessage>().Add(msg);

        if (ticket.Status is TicketStatus.Open or TicketStatus.Assigned)
            ticket.Status = TicketStatus.InProgress;
        ticket.AssignedToAdminId ??= adminId;
        ticket.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(ct);
        return msg;
    }

    public async Task CloseAsync(Guid ticketId, CancellationToken ct = default)
    {
        var ticket = await _db.Set<SupportTicket>().FirstOrDefaultAsync(t => t.Id == ticketId, ct)
            ?? throw new NotFoundAppException();
        ticket.Status = TicketStatus.Closed;
        ticket.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
    }
}
