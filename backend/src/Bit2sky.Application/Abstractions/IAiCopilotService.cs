using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public interface IAiCopilotService
{
    Task<IReadOnlyList<AiSession>> ListSessionsAsync(Guid userId, CancellationToken ct = default);
    Task<AiSession> CreateSessionAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<AiChatMessage>> GetMessagesAsync(Guid userId, Guid sessionId, CancellationToken ct = default);
    Task<AiChatMessage> SendMessageAsync(Guid userId, Guid sessionId, string content, CancellationToken ct = default);
    Task DeleteSessionAsync(Guid userId, Guid sessionId, CancellationToken ct = default);
}
