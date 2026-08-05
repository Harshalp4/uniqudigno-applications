using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Admin management of Claude system prompts (Section 13). Activating a prompt
// deactivates all others so the copilot always resolves a single active prompt.
public class AdminAiPromptService : IAdminAiPromptService
{
    private readonly IAppDbContext _db;

    public AdminAiPromptService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<AiPrompt>> ListAsync(CancellationToken ct = default)
        => await _db.Set<AiPrompt>().AsNoTracking()
            .OrderByDescending(p => p.IsActive).ThenBy(p => p.Name).ThenByDescending(p => p.Version)
            .ToListAsync(ct);

    public async Task<AiPrompt> CreateAsync(AiPromptInput input, Guid adminId, CancellationToken ct = default)
    {
        var name = input.Name.Trim();
        var latest = await _db.Set<AiPrompt>().Where(p => p.Name == name)
            .MaxAsync(p => (int?)p.Version, ct) ?? 0;

        var prompt = new AiPrompt
        {
            Id = Guid.NewGuid(),
            Name = name,
            Version = latest + 1,
            SystemPrompt = input.SystemPrompt,
            Model = input.Model,
            IsActive = false,
            CreatedByAdminId = adminId,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        _db.Set<AiPrompt>().Add(prompt);
        await _db.SaveChangesAsync(ct);

        if (input.IsActive) await ActivateAsync(prompt.Id, ct);
        return prompt;
    }

    public async Task<AiPrompt> UpdateAsync(Guid id, AiPromptInput input, CancellationToken ct = default)
    {
        var prompt = await _db.Set<AiPrompt>().FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundAppException();
        prompt.Name = input.Name.Trim();
        prompt.SystemPrompt = input.SystemPrompt;
        prompt.Model = input.Model;
        await _db.SaveChangesAsync(ct);

        if (input.IsActive && !prompt.IsActive) await ActivateAsync(prompt.Id, ct);
        return prompt;
    }

    public async Task ActivateAsync(Guid id, CancellationToken ct = default)
    {
        var prompt = await _db.Set<AiPrompt>().FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundAppException();

        var others = await _db.Set<AiPrompt>().Where(p => p.IsActive && p.Id != id).ToListAsync(ct);
        foreach (var o in others) o.IsActive = false;
        prompt.IsActive = true;
        await _db.SaveChangesAsync(ct);
    }
}
