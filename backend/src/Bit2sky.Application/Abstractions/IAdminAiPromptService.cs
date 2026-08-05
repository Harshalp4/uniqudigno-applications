using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

// Admin create/edit payload for a Claude system prompt (Section 13).
public record AiPromptInput(string Name, string SystemPrompt, string? Model, bool IsActive);

// Manages versioned Claude system prompts. Exactly one prompt is active at a time —
// the copilot resolves the active prompt server-side (never from the client).
public interface IAdminAiPromptService
{
    Task<IReadOnlyList<AiPrompt>> ListAsync(CancellationToken ct = default);
    Task<AiPrompt> CreateAsync(AiPromptInput input, Guid adminId, CancellationToken ct = default);
    Task<AiPrompt> UpdateAsync(Guid id, AiPromptInput input, CancellationToken ct = default);
    Task ActivateAsync(Guid id, CancellationToken ct = default);
}
