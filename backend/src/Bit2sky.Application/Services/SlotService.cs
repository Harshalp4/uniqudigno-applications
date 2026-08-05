using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Home-collection slots. Hourly windows are materialised per date on first
// request, so availability (capacity vs. booked) is real and DB-backed.
public class SlotService : ISlotService
{
    private readonly IAppDbContext _db;
    public SlotService(IAppDbContext db) => _db = db;

    private static readonly int[] _hours = { 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 };
    private const int SlotCapacity = 5;

    public async Task<IReadOnlyList<SlotDto>> GetAvailableAsync(
        DateOnly date, string? pincode, CancellationToken ct = default)
    {
        var slots = await _db.Set<Slot>().Where(s => s.Date == date).ToListAsync(ct);
        if (slots.Count == 0)
        {
            slots = _hours.Select(h => new Slot
            {
                Id = Guid.NewGuid(),
                Date = date,
                StartTime = new TimeOnly(h, 0),
                EndTime = new TimeOnly(h + 1, 0),
                Capacity = SlotCapacity,
                Booked = 0,
                IsAvailable = true,
            }).ToList();
            _db.Set<Slot>().AddRange(slots);
            await _db.SaveChangesAsync(ct);
        }

        return slots
            .OrderBy(s => s.StartTime)
            .Select(s => new SlotDto(
                s.Id,
                s.StartTime.ToString("HH:mm"),
                s.EndTime.ToString("HH:mm"),
                Period(s.StartTime.Hour),
                s.IsAvailable && s.Booked < s.Capacity))
            .ToList();
    }

    private static string Period(int hour) =>
        hour < 12 ? "Morning" : hour < 16 ? "Afternoon" : "Evening";
}
