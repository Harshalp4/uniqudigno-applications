using System.Net.Http.Headers;
using System.Net.Http.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.SignalR.Client;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// P0d live tracking: owners receive BookingStatusChanged on the per-booking
// group; foreign users cannot join it.
public class BookingTrackingHubTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public BookingTrackingHubTests(TestWebAppFactory factory) => _factory = factory;

    private string IssueToken(Guid userId, string role, string audience)
    {
        using var scope = _factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var (token, _) = jwt.IssueAccessToken(userId, role, Array.Empty<string>(), audience);
        return token;
    }

    private HubConnection Hub(string token) => new HubConnectionBuilder()
        .WithUrl(new Uri(_factory.Server.BaseAddress, "hubs/booking-tracking"), o =>
        {
            o.HttpMessageHandlerFactory = _ => _factory.Server.CreateHandler();
            o.AccessTokenProvider = () => Task.FromResult<string?>(token);
            o.Transports = Microsoft.AspNetCore.Http.Connections.HttpTransportType.LongPolling;
        })
        .Build();

    private async Task<(Guid bookingId, Guid ownerId, Guid techUserId)> SeedAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

        var ownerId = Guid.NewGuid();
        var techUserId = Guid.NewGuid();
        var techId = Guid.NewGuid();
        db.Set<Technician>().Add(new Technician
        {
            Id = techId, UserId = techUserId, EmployeeId = "T" + Guid.NewGuid().ToString("N")[..6],
            Name = "Hub Tech", Mobile = "+9197" + Random.Shared.Next(10000000, 99999999),
            IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
        });

        var bookingId = Guid.NewGuid();
        db.Set<Booking>().Add(new Booking
        {
            Id = bookingId, BookingNumber = "B2S" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
            UserId = ownerId, TechnicianId = techId, Status = BookingStatus.Confirmed,
            CollectionType = SampleCollectionType.HomeCollection,
            ScheduledDate = DateOnly.FromDateTime(DateTime.UtcNow.Date),
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync();
        return (bookingId, ownerId, techUserId);
    }

    [Fact]
    public async Task Owner_ReceivesStatusChanged_WhenTechnicianAdvances()
    {
        var (bookingId, ownerId, techUserId) = await SeedAsync();

        await using var hub = Hub(IssueToken(ownerId, "customer", "flutter_android"));
        var received = new TaskCompletionSource<BookingStatusChangedEvent>(TaskCreationOptions.RunContinuationsAsynchronously);
        hub.On<BookingStatusChangedEvent>("BookingStatusChanged", evt => received.TrySetResult(evt));
        await hub.StartAsync();
        await hub.InvokeAsync("JoinBooking", bookingId.ToString());

        // Drive a status change over HTTP as the assigned technician.
        var techClient = _factory.CreateClient();
        techClient.DefaultRequestHeaders.Add("X-App-Source", "technician");
        techClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", IssueToken(techUserId, "technician", "technician-app"));
        var res = await techClient.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "TechnicianAssigned", sampleBarcode = (string?)null, photoUrl = (string?)null });
        Assert.True(res.IsSuccessStatusCode, await res.Content.ReadAsStringAsync());

        var evt = await received.Task.WaitAsync(TimeSpan.FromSeconds(10));
        Assert.Equal(bookingId, evt.BookingId);
        Assert.Equal("TechnicianAssigned", evt.Status);
    }

    [Fact]
    public async Task ForeignUser_JoinBooking_IsRejected()
    {
        var (bookingId, _, _) = await SeedAsync();

        await using var hub = Hub(IssueToken(Guid.NewGuid(), "customer", "flutter_android"));
        await hub.StartAsync();
        await Assert.ThrowsAsync<HubException>(() => hub.InvokeAsync("JoinBooking", bookingId.ToString()));
    }
}
