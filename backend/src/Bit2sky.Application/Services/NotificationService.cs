using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

public class NotificationService : INotificationService
{
    private readonly IAppDbContext _db;
    public NotificationService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<Notification>> ListAsync(Guid userId, CancellationToken ct = default)
        => await _db.Set<Notification>().AsNoTracking().Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt).Take(100).ToListAsync(ct);

    public Task<int> UnreadCountAsync(Guid userId, CancellationToken ct = default)
        => _db.Set<Notification>().CountAsync(n => n.UserId == userId && !n.IsRead, ct);

    public async Task MarkReadAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var n = await _db.Set<Notification>().FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct)
            ?? throw new NotFoundAppException();
        n.IsRead = true;
        n.ReadAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
    }

    public async Task MarkAllReadAsync(Guid userId, CancellationToken ct = default)
    {
        var items = await _db.Set<Notification>().Where(n => n.UserId == userId && !n.IsRead).ToListAsync(ct);
        foreach (var n in items) { n.IsRead = true; n.ReadAt = DateTimeOffset.UtcNow; }
        await _db.SaveChangesAsync(ct);
    }

    public async Task<int> BroadcastAsync(string title, string body, string? deepLink, CancellationToken ct = default)
    {
        var userIds = await _db.Set<User>()
            .Where(u => u.IsActive && !u.IsDeleted && !u.IsAdminPortalUser)
            .Select(u => u.Id).ToListAsync(ct);

        var now = DateTimeOffset.UtcNow;
        foreach (var uid in userIds)
        {
            _db.Set<Notification>().Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = uid,
                Title = title,
                Body = body,
                Channel = NotificationChannel.InApp,
                Status = NotificationStatus.Sent,
                DeepLink = deepLink,
                CreatedAt = now,
            });
        }
        await _db.SaveChangesAsync(ct);
        return userIds.Count;
    }

    public async Task<IReadOnlyList<Notification>> RecentAsync(int take, CancellationToken ct = default)
        => await _db.Set<Notification>().AsNoTracking()
            .OrderByDescending(n => n.CreatedAt).Take(Math.Clamp(take, 1, 200)).ToListAsync(ct);

    public async Task RegisterDeviceAsync(Guid userId, string fcmToken, DevicePlatform platform, CancellationToken ct = default)
    {
        var device = await _db.Set<Device>().FirstOrDefaultAsync(d => d.UserId == userId && d.FcmToken == fcmToken, ct);
        if (device is null)
        {
            device = new Device { Id = Guid.NewGuid(), UserId = userId, FcmToken = fcmToken, Platform = platform };
            _db.Set<Device>().Add(device);
        }
        device.IsActive = true;
        device.LastSeenAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
    }
}
