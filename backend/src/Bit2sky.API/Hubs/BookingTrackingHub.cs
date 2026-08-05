using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Bit2sky.API.Hubs;

/// Live booking tracking (P0d). Clients join a per-booking group and receive
/// "BookingStatusChanged" events (see BookingStatusChangedEvent). Group joins
/// are authorized via the same ownership rules as the REST detail endpoint.
[Authorize]
public class BookingTrackingHub : Hub
{
    public static string GroupFor(Guid bookingId) => $"booking-{bookingId}";

    private readonly IOwnershipService _ownership;

    public BookingTrackingHub(IOwnershipService ownership) => _ownership = ownership;

    public async Task JoinBooking(string bookingId)
    {
        if (!Guid.TryParse(bookingId, out var id))
            throw new HubException("Not allowed");

        var sub = Context.UserIdentifier ?? Context.User?.FindFirst("sub")?.Value;
        var role = Context.User?.FindFirst("role")?.Value ?? "customer";
        if (!Guid.TryParse(sub, out var userId) ||
            !await _ownership.CanAccessBookingAsync(userId, role, null, id, Context.ConnectionAborted))
            throw new HubException("Not allowed"); // same message for missing/foreign (no enumeration)

        await Groups.AddToGroupAsync(Context.ConnectionId, GroupFor(id), Context.ConnectionAborted);
    }

    public Task LeaveBooking(string bookingId)
        => Guid.TryParse(bookingId, out var id)
            ? Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupFor(id), Context.ConnectionAborted)
            : Task.CompletedTask;
}
