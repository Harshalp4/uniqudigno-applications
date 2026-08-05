using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

// Support ticket as seen by an agent — customer contact is masked (PHI, Section 4B).
public record AdminTicketDto(
    Guid Id, string TicketNumber, string Customer, string Subject, string Category,
    string Status, string Priority, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

// Admin support queue (Section 11) — all tickets, agent replies, close.
public interface IAdminSupportService
{
    Task<IReadOnlyList<AdminTicketDto>> ListAsync(string? status, CancellationToken ct = default);
    Task<IReadOnlyList<SupportMessage>> GetMessagesAsync(Guid ticketId, CancellationToken ct = default);
    Task<SupportMessage> ReplyAsync(Guid ticketId, Guid adminId, string body, CancellationToken ct = default);
    Task CloseAsync(Guid ticketId, CancellationToken ct = default);
}
