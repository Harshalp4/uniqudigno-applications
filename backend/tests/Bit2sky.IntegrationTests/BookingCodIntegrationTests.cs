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

// P0b cash-on-collection: collecting the sample requires an explicit cash
// confirmation and flips the payment to Paid in the same transaction; online
// bookings are unaffected by the codCollected flag.
public class BookingCodIntegrationTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public BookingCodIntegrationTests(TestWebAppFactory factory) => _factory = factory;

    private async Task<(Guid bookingId, Guid paymentId)> SeedBookingAsync(
        Guid techUserId, PaymentMethod method, BookingStatus status = BookingStatus.TechnicianAssigned)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

        var techId = Guid.NewGuid();
        db.Set<Technician>().Add(new Technician
        {
            Id = techId, UserId = techUserId, EmployeeId = "T" + Guid.NewGuid().ToString("N")[..6],
            Name = "Field Tech", Mobile = "+9198" + Random.Shared.Next(10000000, 99999999),
            IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
        });

        var bookingId = Guid.NewGuid();
        db.Set<Booking>().Add(new Booking
        {
            Id = bookingId, BookingNumber = "B2S" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
            UserId = Guid.NewGuid(), TechnicianId = techId, Status = status,
            CollectionType = SampleCollectionType.HomeCollection,
            ScheduledDate = DateOnly.FromDateTime(DateTime.UtcNow.Date),
            AmountPayable = 299,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        });

        var paymentId = Guid.NewGuid();
        db.Set<Payment>().Add(new Payment
        {
            Id = paymentId, BookingId = bookingId, UserId = Guid.NewGuid(),
            Amount = 299, Method = method, Status = PaymentStatus.Created,
            CreatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync();
        return (bookingId, paymentId);
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
    public async Task CodCollection_WithoutCashConfirmation_Returns400()
    {
        var techUserId = Guid.NewGuid();
        var (bookingId, _) = await SeedBookingAsync(techUserId, PaymentMethod.CashOnCollection);
        var client = TechClient(techUserId);

        var res = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "SampleCollected", sampleBarcode = "B2S-SMPL-1", photoUrl = (string?)null });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
        Assert.Contains("codCollected", await res.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task CodCollection_WithCashConfirmation_MarksPaymentPaid()
    {
        var techUserId = Guid.NewGuid();
        var (bookingId, paymentId) = await SeedBookingAsync(techUserId, PaymentMethod.CashOnCollection);
        var client = TechClient(techUserId);

        var res = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "SampleCollected", sampleBarcode = "B2S-SMPL-2", photoUrl = (string?)null, codCollected = true });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
        var payment = await db.Set<Payment>().AsNoTracking().FirstAsync(p => p.Id == paymentId);
        Assert.Equal(PaymentStatus.Paid, payment.Status);
        Assert.NotNull(payment.PaidAt);
        Assert.Equal(PaymentMethod.CashOnCollection, payment.Method);
    }

    [Fact]
    public async Task OnlineBooking_Collection_DoesNotRequireCodFlag()
    {
        var techUserId = Guid.NewGuid();
        var (bookingId, paymentId) = await SeedBookingAsync(techUserId, PaymentMethod.Upi);
        var client = TechClient(techUserId);

        var res = await client.PutAsJsonAsync($"/api/v1/technician/bookings/{bookingId}/status",
            new { status = "SampleCollected", sampleBarcode = "B2S-SMPL-3", photoUrl = (string?)null });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
        var payment = await db.Set<Payment>().AsNoTracking().FirstAsync(p => p.Id == paymentId);
        // Online payments are settled via the gateway confirm, not field collection.
        Assert.Equal(PaymentStatus.Created, payment.Status);
    }
}
