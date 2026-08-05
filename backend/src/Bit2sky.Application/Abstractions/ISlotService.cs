namespace Bit2sky.Application.Abstractions;

/// A home-collection time slot as the app displays it.
public record SlotDto(Guid Id, string StartTime, string EndTime, string Period, bool Available);

public interface ISlotService
{
    /// Available slots for a date (lazily materialised on first request).
    Task<IReadOnlyList<SlotDto>> GetAvailableAsync(DateOnly date, string? pincode, CancellationToken ct = default);
}
