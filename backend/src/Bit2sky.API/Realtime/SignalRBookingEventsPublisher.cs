using Bit2sky.API.Hubs;
using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.SignalR;

namespace Bit2sky.API.Realtime;

/// SignalR-backed booking event broadcast (P0d). Lives in the API layer so
/// Application stays free of the SignalR dependency. Broadcast failures are
/// logged and swallowed — the state change has already committed.
public class SignalRBookingEventsPublisher : IBookingEventsPublisher
{
    private readonly IHubContext<BookingTrackingHub> _hub;
    private readonly ILogger<SignalRBookingEventsPublisher> _log;

    public SignalRBookingEventsPublisher(IHubContext<BookingTrackingHub> hub, ILogger<SignalRBookingEventsPublisher> log)
    {
        _hub = hub;
        _log = log;
    }

    public async Task PublishAsync(BookingStatusChangedEvent evt, CancellationToken ct = default)
    {
        try
        {
            await _hub.Clients.Group(BookingTrackingHub.GroupFor(evt.BookingId))
                .SendAsync("BookingStatusChanged", evt, ct);
        }
        catch (Exception ex)
        {
            _log.LogWarning(ex, "Booking tracking broadcast failed for {BookingId}", evt.BookingId);
        }
    }
}
