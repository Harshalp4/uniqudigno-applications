using Anthropic;
using Anthropic.Models.Messages;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.Configuration;

namespace Bit2sky.Infrastructure.AI;

// Anthropic Claude proxy (Section 13). API key from Key Vault/config — never in code.
public class ClaudeAiService : IClaudeAiService
{
    private const string DefaultModel = "claude-opus-4-8";
    private const long MaxTokens = 1024;

    private readonly AnthropicClient _client;

    public ClaudeAiService(IConfiguration config)
    {
        var apiKey = config["Anthropic:ApiKey"] ?? Environment.GetEnvironmentVariable("ANTHROPIC_API_KEY");
        _client = new AnthropicClient { ApiKey = apiKey };
    }

    public async Task<string> CompleteAsync(
        string systemPrompt,
        IReadOnlyList<AiChatTurn> messages,
        string? model = null,
        CancellationToken ct = default)
    {
        var requestMessages = messages
            .Select(m => new MessageParam
            {
                Role = m.Role.Equals("assistant", StringComparison.OrdinalIgnoreCase) ? Role.Assistant : Role.User,
                Content = m.Content,
            })
            .ToList();

        var response = await _client.Messages.Create(new MessageCreateParams
        {
            Model = model ?? DefaultModel,
            MaxTokens = MaxTokens,
            System = systemPrompt,
            Messages = requestMessages,
        });

        return string.Concat(response.Content
            .Select(b => b.Value)
            .OfType<TextBlock>()
            .Select(t => t.Text));
    }
}
