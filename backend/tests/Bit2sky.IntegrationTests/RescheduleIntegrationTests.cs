using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// P0c reschedule: ownership, window, retry limit, and atomic slot seat swap.
public class RescheduleIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public RescheduleIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    private static DateOnly FarDate => DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(3));

    private async Task<(Guid bookingId, Guid oldSlotId, Guid newSlotId)> SeedAsync(
        Guid userId, int rescheduleCount = 0, int newSlotCapacity = 5)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

        var oldSlot = new Slot
        {
            Id = Guid.NewGuid(), Date = FarDate, StartTime = new TimeOnly(9, 0), EndTime = new TimeOnly(10, 0),
            Capacity = 5, Booked = 1, IsAvailable = true,
        };
        var newSlot = new Slot
        {
            Id = Guid.NewGuid(), Date = FarDate.AddDays(1), StartTime = new TimeOnly(11, 0), EndTime = new TimeOnly(12, 0),
            Capacity = newSlotCapacity, Booked = 0, IsAvailable = true,
        };
        db.Set<Slot>().AddRange(oldSlot, newSlot);

        var bookingId = Guid.NewGuid();
        db.Set<Booking>().Add(new Booking
        {
            Id = bookingId, BookingNumber = "B2S" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
            UserId = userId, Status = BookingStatus.Confirmed, SlotId = oldSlot.Id,
            ScheduledDate = FarDate, ScheduledTime = new TimeOnly(9, 0),
            RescheduleCount = rescheduleCount,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync();
        return (bookingId, oldSlot.Id, newSlot.Id);
    }

    private HttpClient CustomerClient(Guid userId)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "flutter_android");
        using var scope = _factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var (token, _) = jwt.IssueAccessToken(userId, "customer", Array.Empty<string>(), "flutter_android");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task Reschedule_HappyPath_SwapsSlotSeatsAndResetsTechnician()
    {
        var userId = Guid.NewGuid();
        var (bookingId, oldSlotId, newSlotId) = await SeedAsync(userId);
        var client = CustomerClient(userId);

        var res = await client.PostAsJsonAsync($"/api/v1/bookings/{bookingId}/reschedule",
            new { scheduledDate = FarDate.AddDays(1).ToString("yyyy-MM-dd"), slotId = newSlotId });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
        var booking = await db.Set<Booking>().AsNoTracking().FirstAsync(b => b.Id == bookingId);
        Assert.Equal(BookingStatus.Rescheduled, booking.Status);
        Assert.Equal(1, booking.RescheduleCount);
        Assert.Null(booking.TechnicianId);
        Assert.Equal(newSlotId, booking.SlotId);

        var oldSlot = await db.Set<Slot>().AsNoTracking().FirstAsync(s => s.Id == oldSlotId);
        var newSlot = await db.Set<Slot>().AsNoTracking().FirstAsync(s => s.Id == newSlotId);
        Assert.Equal(0, oldSlot.Booked);
        Assert.Equal(1, newSlot.Booked);
    }

    [Fact]
    public async Task Reschedule_ToFullSlot_Returns400_AndKeepsOldSlot()
    {
        var userId = Guid.NewGuid();
        var (bookingId, oldSlotId, newSlotId) = await SeedAsync(userId, newSlotCapacity: 0);
        var client = CustomerClient(userId);

        var res = await client.PostAsJsonAsync($"/api/v1/bookings/{bookingId}/reschedule",
            new { scheduledDate = FarDate.AddDays(1).ToString("yyyy-MM-dd"), slotId = newSlotId });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
        var booking = await db.Set<Booking>().AsNoTracking().FirstAsync(b => b.Id == bookingId);
        Assert.Equal(oldSlotId, booking.SlotId);
        Assert.Equal(0, booking.RescheduleCount);
        var oldSlot = await db.Set<Slot>().AsNoTracking().FirstAsync(s => s.Id == oldSlotId);
        Assert.Equal(1, oldSlot.Booked); // seat NOT released on failure
    }

    [Fact]
    public async Task Reschedule_PastLimit_Returns409()
    {
        var userId = Guid.NewGuid();
        var (bookingId, _, newSlotId) = await SeedAsync(userId, rescheduleCount: 2); // default max = 2
        var client = CustomerClient(userId);

        var res = await client.PostAsJsonAsync($"/api/v1/bookings/{bookingId}/reschedule",
            new { scheduledDate = FarDate.AddDays(1).ToString("yyyy-MM-dd"), slotId = newSlotId });
        Assert.Equal(HttpStatusCode.Conflict, res.StatusCode);
    }

    [Fact]
    public async Task Reschedule_InsideWindow_Returns409()
    {
        var userId = Guid.NewGuid();
        Guid bookingId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
            bookingId = Guid.NewGuid();
            db.Set<Booking>().Add(new Booking
            {
                Id = bookingId, BookingNumber = "B2S" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
                UserId = userId, Status = BookingStatus.Confirmed,
                // Scheduled 1h from now — inside the 4h reschedule window.
                ScheduledDate = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(1).Date),
                ScheduledTime = TimeOnly.FromDateTime(DateTime.UtcNow.AddHours(1)),
                CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
            });
            await db.SaveChangesAsync();
        }
        var client = CustomerClient(userId);

        var res = await client.PostAsJsonAsync($"/api/v1/bookings/{bookingId}/reschedule",
            new { scheduledDate = FarDate.ToString("yyyy-MM-dd") });
        Assert.Equal(HttpStatusCode.Conflict, res.StatusCode);
    }

    [Fact]
    public async Task Reschedule_ForeignBooking_Returns403()
    {
        var owner = Guid.NewGuid();
        var (bookingId, _, newSlotId) = await SeedAsync(owner);
        var client = CustomerClient(Guid.NewGuid()); // different user

        var res = await client.PostAsJsonAsync($"/api/v1/bookings/{bookingId}/reschedule",
            new { scheduledDate = FarDate.AddDays(1).ToString("yyyy-MM-dd"), slotId = newSlotId });
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }
}
