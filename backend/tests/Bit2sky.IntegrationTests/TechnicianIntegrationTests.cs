using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bit2sky.IntegrationTests;

// Technician field app: own assigned jobs only, server-validated status flow,
// barcode required to mark SampleCollected.
public class TechnicianIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public TechnicianIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    // Seeds a technician linked to userId with one Confirmed booking; returns the booking id.
    private async Task<Guid> SeedAssignedBookingAsync(Guid userId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

        var techId = Guid.NewGuid();
        db.Set<Technician>().Add(new Technician
        {
            Id = techId, UserId = userId, EmployeeId = "T" + Guid.NewGuid().ToString("N")[..6],
            Name = "Field Tech", Mobile = "+9199" + Random.Shared.Next(10000000, 99999999),
            IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
        });

        var bookingId = Guid.NewGuid();
        db.Set<Booking>().Add(new Booking
        {
            Id = bookingId, BookingNumber = "B2S" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
            UserId = Guid.NewGuid(), TechnicianId = techId, Status = BookingStatus.Confirmed,
            CollectionType = SampleCollectionType.HomeCollection,
            ScheduledDate = DateOnly.FromDateTime(DateTime.UtcNow.Date),
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync();
        return bookingId;
    }

    private HttpClient TechClient(Guid userId)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Source", "technician");
        using var scope = _factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var (token, _) = jwt.IssueAccessToken(userId, "technician", Array.Empty<string>(), "technician-app");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task Technician_SeesOwnBookings_AndAdvancesThroughCollection()
    {
        var userId = Guid.NewGuid();
        var bookingId = await SeedAssignedBookingAsync(userId);
        var client = TechClient(userId);

        var list = await client.GetAsync("/api/v1/technician/bookings");
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);
        Assert.Contains(bookingId.ToString(), await list.Content.ReadAsStringAsync());

        // Confirmed → TechnicianAssigned (no barcode needed).
        var onWay = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "TechnicianAssigned", sampleBarcode = (string?)null, photoUrl = (string?)null });
        Assert.Equal(HttpStatusCode.OK, onWay.StatusCode);

        // → SampleCollected WITHOUT barcode is rejected (400).
        var noBarcode = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "SampleCollected", sampleBarcode = (string?)null, photoUrl = (string?)null });
        Assert.Equal(HttpStatusCode.BadRequest, noBarcode.StatusCode);

        // → SampleCollected WITH barcode succeeds.
        var collected = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "SampleCollected", sampleBarcode = "B2S-SMPL-2048", photoUrl = (string?)null });
        Assert.Equal(HttpStatusCode.OK, collected.StatusCode);
    }

    [Fact]
    public async Task Technician_CannotAdvanceUnassignedBooking_Returns404()
    {
        var userId = Guid.NewGuid();
        await SeedAssignedBookingAsync(userId); // makes userId a technician, but not owner of the target
        var client = TechClient(userId);

        var res = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{Guid.NewGuid()}/status",
            new { status = "TechnicianAssigned", sampleBarcode = (string?)null, photoUrl = (string?)null });
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task NonTechnicianUser_ListBookings_Returns403()
    {
        // A user with no Technician row cannot use the technician endpoints.
        var client = TechClient(Guid.NewGuid());
        var res = await client.GetAsync("/api/v1/technician/bookings");
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }
}
