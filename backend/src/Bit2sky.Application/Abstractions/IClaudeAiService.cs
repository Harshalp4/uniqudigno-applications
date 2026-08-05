namespace Bit2sky.Application.Abstractions;

public record AiChatTurn(string Role, string Content);

// Anthropic Claude proxy (Section 13). Backend-only; system prompt prepended;
// report context injected server-side; never called from clients.
public interface IClaudeAiService
{
    Task<string> CompleteAsync(
        string systemPrompt,
        IReadOnlyList<AiChatTurn> messages,
        string? model = null,
        CancellationToken ct = default);
}
