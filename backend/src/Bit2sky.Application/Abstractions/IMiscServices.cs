using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public record CreateTicketRequest(string Subject, string Category, string Message);
public interface ISupportService
{
    Task<SupportTicket> CreateAsync(Guid userId, CreateTicketRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<SupportTicket>> ListAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<SupportMessage>> GetMessagesAsync(Guid userId, Guid ticketId, CancellationToken ct = default);
    Task<SupportMessage> AddMessageAsync(Guid userId, Guid ticketId, string body, CancellationToken ct = default);
    Task CloseAsync(Guid userId, Guid ticketId, CancellationToken ct = default);
}

public interface IContentService
{
    Task<IReadOnlyList<Banner>> GetBannersAsync(CancellationToken ct = default);
    Task<IReadOnlyList<Article>> GetArticlesAsync(bool featuredOnly, string? lang = null, CancellationToken ct = default);
    Task<Article> GetArticleBySlugAsync(string slug, CancellationToken ct = default);
}

public interface IPartnerService
{
    Task<object> GetDashboardAsync(Guid partnerId, CancellationToken ct = default);
    Task<IReadOnlyList<PartnerCommission>> GetCommissionsAsync(Guid partnerId, CancellationToken ct = default);
}
