using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Wellio AI copilot (Section 13). Rate limited, own sessions only, prompt from DB,
// prompt-injection guard, report context injected server-side.
public class AiCopilotService : IAiCopilotService
{
    private const string FallbackSystemPrompt =
        "You are Wellio, a friendly health assistant for Unique Diagnostic Centre. Provide general wellness "
        + "guidance only; never diagnose. Encourage consulting a doctor for medical concerns.";

    private readonly IAppDbContext _db;
    private readonly IClaudeAiService _claude;
    private readonly IInputSanitizationService _sanitizer;
    private readonly IRateLimitEnforcer _rateLimit;

    public AiCopilotService(IAppDbContext db, IClaudeAiService claude,
        IInputSanitizationService sanitizer, IRateLimitEnforcer rateLimit)
    {
        _db = db;
        _claude = claude;
        _sanitizer = sanitizer;
        _rateLimit = rateLimit;
    }

    public async Task<IReadOnlyList<AiSession>> ListSessionsAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<AiSession>().AsNoTracking()
            .Where(s => s.UserId == userId && s.Status != AiSessionStatus.Deleted)
            .OrderByDescending(s => s.UpdatedAt).ToListAsync(ct);

    public async Task<AiSession> CreateSessionAsync(Guid userId, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("ai_session", userId.ToString(), ct);
        var promptId = await _db.Set<AiPrompt>().Where(p => p.IsActive)
            .OrderByDescending(p => p.Version).Select(p => (Guid?)p.Id).FirstOrDefaultAsync(ct);

        var session = new AiSession
        {
            Id = Guid.NewGuid(), UserId = userId, Status = AiSessionStatus.Active,
            PromptVersionId = promptId, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        };
        _db.Set<AiSession>().Add(session);
        await _db.SaveChangesAsync(ct);
        return session;
    }

    public async Task<IReadOnlyList<AiChatMessage>> GetMessagesAsync(Guid userId, Guid sessionId, CancellationToken ct = default)
    {
        await EnsureOwnedAsync(userId, sessionId, ct);
        return await _db.Set<AiChatMessage>().AsNoTracking()
            .Where(m => m.SessionId == sessionId).OrderBy(m => m.CreatedAt).ToListAsync(ct);
    }

    public async Task<AiChatMessage> SendMessageAsync(Guid userId, Guid sessionId, string content, CancellationToken ct = default)
    {
        await _rateLimit.EnforceAsync("ai_message", userId.ToString(), ct);
        var session = await EnsureOwnedAsync(userId, sessionId, ct);

        // Prompt-injection guard — strip override patterns before the model sees them.
        var cleanContent = _sanitizer.StripPromptInjection(content);

        var systemPrompt = await ResolveSystemPromptAsync(session, ct);
        systemPrompt += await BuildReportContextAsync(userId, ct); // injected server-side, not from client

        var history = await _db.Set<AiChatMessage>()
            .Where(m => m.SessionId == sessionId)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new AiChatTurn(m.Role == AiMessageRole.Assistant ? "assistant" : "user", m.Content))
            .ToListAsync(ct);
        history.Add(new AiChatTurn("user", cleanContent));

        var userMessage = new AiChatMessage
        {
            Id = Guid.NewGuid(), SessionId = sessionId, Role = AiMessageRole.User,
            Content = cleanContent, CreatedAt = DateTimeOffset.UtcNow,
        };
        _db.Set<AiChatMessage>().Add(userMessage);

        var answer = await _claude.CompleteAsync(systemPrompt, history, ct: ct);

        var assistantMessage = new AiChatMessage
        {
            Id = Guid.NewGuid(), SessionId = sessionId, Role = AiMessageRole.Assistant,
            Content = answer, CreatedAt = DateTimeOffset.UtcNow,
        };
        _db.Set<AiChatMessage>().Add(assistantMessage);
        session.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);

        return assistantMessage;
    }

    public async Task DeleteSessionAsync(Guid userId, Guid sessionId, CancellationToken ct = default)
    {
        var session = await EnsureOwnedAsync(userId, sessionId, ct);
        session.Status = AiSessionStatus.Deleted;
        var messages = await _db.Set<AiChatMessage>().Where(m => m.SessionId == sessionId).ToListAsync(ct);
        _db.Set<AiChatMessage>().RemoveRange(messages); // PHI cleared
        await _db.SaveChangesAsync(ct);
    }

    private async Task<AiSession> EnsureOwnedAsync(Guid userId, Guid sessionId, CancellationToken ct)
        => await _db.Set<AiSession>().FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == userId, ct)
           ?? throw new NotFoundAppException();

    private async Task<string> ResolveSystemPromptAsync(AiSession session, CancellationToken ct)
    {
        var prompt = await _db.Set<AiPrompt>().AsNoTracking()
            .Where(p => p.IsActive).OrderByDescending(p => p.Version)
            .Select(p => p.SystemPrompt).FirstOrDefaultAsync(ct);
        return prompt ?? FallbackSystemPrompt;
    }

    private async Task<string> BuildReportContextAsync(Guid userId, CancellationToken ct)
    {
        var latest = await _db.Set<LabReport>().AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == ReportStatus.Ready)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => r.Title)
            .FirstOrDefaultAsync(ct);
        return latest is null ? string.Empty : $"\n\nContext: the user's latest report is \"{latest}\".";
    }
}
