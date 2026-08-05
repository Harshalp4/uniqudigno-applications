using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Bit2sky.Shared;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Booking lifecycle with ownership + role filtering + Razorpay (Section 7 / 3C).
public class BookingService : IBookingService
{
    private readonly IAppDbContext _db;
    private readonly IRazorpayService _razorpay;
    private readonly IOwnershipService _ownership;
    private readonly IDataMaskingService _mask;
    private readonly IBookingEventsPublisher _events;

    public BookingService(IAppDbContext db, IRazorpayService razorpay, IOwnershipService ownership,
        IDataMaskingService mask, IBookingEventsPublisher events)
    {
        _db = db;
        _razorpay = razorpay;
        _ownership = ownership;
        _mask = mask;
        _events = events;
    }

    // Fire the tracking broadcast AFTER the state change committed; payment
    // status is looked up when the caller doesn't already have it.
    private async Task PublishStatusAsync(Booking booking, string? paymentStatus, CancellationToken ct)
    {
        paymentStatus ??= (await _db.Set<Payment>().AsNoTracking()
            .Where(p => p.BookingId == booking.Id).Select(p => (PaymentStatus?)p.Status).FirstOrDefaultAsync(ct)
            ?? PaymentStatus.Created).ToString();
        await _events.PublishAsync(new BookingStatusChangedEvent(
            booking.Id, booking.BookingNumber, booking.Status.ToString(),
            paymentStatus, booking.RescheduleCount, booking.UpdatedAt), ct);
    }

    public async Task<CreateBookingResult> CreateAsync(Guid userId, CreateBookingRequest req, CancellationToken ct = default)
    {
        var cart = await _db.Set<Cart>().Include(c => c.Items).FirstOrDefaultAsync(c => c.UserId == userId, ct);
        if (cart is null || cart.Items.Count == 0)
            throw new ValidationAppException(new[] { new ApiError { Field = "cart", Message = "Cart is empty" } });

        // Ownership (IDOR guard): the address must belong to the caller.
        if (req.AddressId is Guid addrId &&
            !await _db.Set<Address>().AnyAsync(a => a.Id == addrId && a.UserId == userId, ct))
            throw new ValidationAppException(new[] { new ApiError { Field = "addressId", Message = "Invalid address" } });

        // Resolve + snapshot the patient (self = account holder, else a family member).
        string? patientName;
        Gender? patientGender;
        DateOnly? patientDob;
        if (req.FamilyMemberId is Guid famId)
        {
            var fam = await _db.Set<FamilyMember>().AsNoTracking()
                .FirstOrDefaultAsync(m => m.Id == famId && m.UserId == userId && !m.IsDeleted, ct);
            if (fam is null)
                throw new ValidationAppException(new[] { new ApiError { Field = "familyMemberId", Message = "Invalid family member" } });
            patientName = fam.Name;
            patientGender = fam.Gender;
            patientDob = fam.DateOfBirth;
        }
        else
        {
            var self = await _db.Set<User>().AsNoTracking().FirstAsync(u => u.Id == userId, ct);
            patientName = self.Name;
            patientGender = self.Gender;
            patientDob = self.DateOfBirth;
        }

        // Slot (optional): read (no-track) for an early 400 and to snapshot the start time.
        // The actual seat reservation is done atomically just before SaveChanges (below)
        // so concurrent bookings cannot oversell the slot.
        Slot? slot = null;
        if (req.SlotId is Guid slotId)
        {
            slot = await _db.Set<Slot>().AsNoTracking().FirstOrDefaultAsync(s => s.Id == slotId, ct);
            if (slot is null || !slot.IsAvailable || slot.Booked >= slot.Capacity)
                throw new ValidationAppException(new[] { new ApiError { Field = "slotId", Message = "Slot is no longer available" } });
        }

        var itemsTotal = cart.Items.Sum(i => i.Price);
        var discount = cart.Items.Sum(i => i.Mrp - i.Price);

        // Coupon: re-validated at checkout; usage counted only when the booking
        // is actually created.
        Coupon? coupon = null;
        var couponDiscount = 0m;
        if (cart.CouponId is { } couponId)
        {
            coupon = await _db.Set<Coupon>().FirstOrDefaultAsync(c => c.Id == couponId, ct);
            var (couponOk, amount, _) = CartService.ValidateCoupon(coupon, itemsTotal);
            if (couponOk && coupon is not null && coupon.PerUserLimit > 0)
            {
                var used = await _db.Set<Booking>()
                    .CountAsync(b => b.UserId == userId && b.CouponId == coupon.Id, ct);
                if (used >= coupon.PerUserLimit) couponOk = false;
            }
            if (couponOk) couponDiscount = amount; else coupon = null;
        }

        var tiersRaw = await _db.Set<AppConfig>()
            .Where(c => c.Key == "group_discount_tiers")
            .Select(c => c.Value).FirstOrDefaultAsync(ct);
        var groupDiscount = CartService.GroupDiscountFor(
            cart.Items.Select(i => (i.PackageId, i.FamilyMemberId, i.Price)),
            CartService.ParseTiers(tiersRaw));

        var payable = Math.Max(0,
            itemsTotal - couponDiscount - groupDiscount - cart.WalletPointsApplied);
        var isCod = string.Equals(req.PaymentMethod, "cod", StringComparison.OrdinalIgnoreCase);

        // Wallet-points combo: debit the wallet in the SAME unit of work as the
        // booking (balance re-checked here — the cart-time cap check is advisory).
        Wallet? wallet = null;
        if (cart.WalletPointsApplied > 0)
        {
            wallet = await _db.Set<Wallet>().FirstOrDefaultAsync(w => w.UserId == userId, ct);
            if (wallet is null || wallet.Balance < cart.WalletPointsApplied)
                throw new ValidationAppException(new[] { new ApiError { Field = "wallet", Message = "Insufficient wallet balance" } });
        }

        var booking = new Booking
        {
            Id = Guid.NewGuid(),
            BookingNumber = "B2S" + DateTimeOffset.UtcNow.Ticks.ToString()[^10..],
            UserId = userId,
            FamilyMemberId = req.FamilyMemberId,
            PatientName = patientName,
            PatientGender = patientGender,
            PatientDateOfBirth = patientDob,
            AddressId = req.AddressId,
            SlotId = req.SlotId,
            ScheduledDate = req.ScheduledDate,
            ScheduledTime = req.ScheduledTime ?? slot?.StartTime,
            // COD needs no gateway confirmation: the booking is actionable immediately
            // ("confirmed booking, unpaid cash") — otherwise it would be stuck Pending
            // forever since ConfirmAsync demands a Razorpay HMAC.
            Status = isCod ? BookingStatus.Confirmed : BookingStatus.Pending,
            ItemsTotal = itemsTotal,
            DiscountTotal = discount + couponDiscount + groupDiscount,
            CouponId = coupon?.Id,
            WalletApplied = cart.WalletPointsApplied,
            AmountPayable = payable,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            Items = cart.Items.Select(i => new BookingItem
            {
                Id = Guid.NewGuid(),
                TestId = i.TestId,
                PackageId = i.PackageId,
                ItemName = i.ItemName,
                Mrp = i.Mrp,
                Price = i.Price,
            }).ToList(),
        };
        _db.Set<Booking>().Add(booking);

        // Gateway order only for online payments with something left to charge.
        // COD and fully-wallet-covered bookings never touch Razorpay.
        string? orderId = null;
        if (!isCod && payable > 0)
            orderId = await _razorpay.CreateOrderAsync(payable, "INR", booking.BookingNumber, ct);

        _db.Set<Payment>().Add(new Payment
        {
            Id = Guid.NewGuid(),
            BookingId = booking.Id,
            UserId = userId,
            RazorpayOrderId = orderId,
            Amount = payable,
            Method = isCod ? PaymentMethod.CashOnCollection : PaymentMethod.Upi,
            Status = PaymentStatus.Created,
            CreatedAt = DateTimeOffset.UtcNow,
        });

        // Debit the wallet points actually consumed by this booking.
        if (wallet is not null)
        {
            wallet.Balance -= cart.WalletPointsApplied;
            wallet.UpdatedAt = DateTimeOffset.UtcNow;
            _db.Set<WalletTransaction>().Add(new WalletTransaction
            {
                Id = Guid.NewGuid(),
                WalletId = wallet.Id,
                Type = WalletTransactionType.Debit,
                Reason = WalletTransactionReason.Redemption,
                Amount = cart.WalletPointsApplied,
                BalanceAfter = wallet.Balance,
                Note = booking.BookingNumber,
            });
        }

        // Atomically reserve one seat: the conditional UPDATE increments Booked only
        // while capacity remains, so two concurrent bookings for the last seat can't
        // both succeed (fixes the earlier check-then-increment TOCTOU / oversell race).
        if (req.SlotId is Guid reserveSlotId &&
            !await _db.TryReserveSlotSeatAsync(reserveSlotId, ct))
            throw new ValidationAppException(new[] { new ApiError { Field = "slotId", Message = "Slot is no longer available" } });

        if (coupon is not null) coupon.UsedCount++;

        // Clear the cart on checkout.
        _db.Set<CartItem>().RemoveRange(cart.Items);
        cart.WalletPointsApplied = 0;
        cart.CouponId = null;

        await _db.SaveChangesAsync(ct);
        // KeyId rides along only when the client actually needs to open the
        // checkout sheet (online + configured gateway + a real order).
        var keyId = orderId is not null && _razorpay.IsConfigured ? _razorpay.KeyId : null;
        return new CreateBookingResult(booking.Id, booking.BookingNumber, orderId, payable, keyId);
    }

    public async Task ConfirmAsync(Guid userId, Guid bookingId, ConfirmBookingRequest req, CancellationToken ct = default)
    {
        var booking = await _db.Set<Booking>().FirstOrDefaultAsync(b => b.Id == bookingId, ct)
            ?? throw new NotFoundAppException();
        if (booking.UserId != userId) throw new ForbiddenAppException();

        var payment = await _db.Set<Payment>().FirstOrDefaultAsync(p => p.BookingId == bookingId, ct)
            ?? throw new NotFoundAppException();

        // Zero-amount bookings (fully wallet-covered) have no gateway charge to
        // verify; everything else must present a valid Razorpay HMAC.
        if (payment.Amount > 0 &&
            !_razorpay.VerifyPaymentSignature(payment.RazorpayOrderId ?? "", req.RazorpayPaymentId, req.RazorpaySignature))
            throw new UnauthorizedAppException(); // invalid HMAC ⇒ 401

        payment.RazorpayPaymentId = string.IsNullOrEmpty(req.RazorpayPaymentId) ? null : req.RazorpayPaymentId;
        payment.RazorpaySignature = string.IsNullOrEmpty(req.RazorpaySignature) ? null : req.RazorpaySignature;
        payment.Status = PaymentStatus.Paid;
        payment.PaidAt = DateTimeOffset.UtcNow;
        booking.Status = BookingStatus.Confirmed;
        booking.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        await PublishStatusAsync(booking, PaymentStatus.Paid.ToString(), ct);
    }

    public async Task<BookingDetailDto> GetAsync(Guid userId, string role, Guid? partnerId, Guid bookingId, CancellationToken ct = default)
    {
        if (!await _ownership.CanAccessBookingAsync(userId, role, partnerId, bookingId, ct))
            throw new NotFoundAppException(); // 404 parity to avoid enumeration
        var b = await _db.Set<Booking>().AsNoTracking()
            .Include(x => x.Items).Include(x => x.Payment)
            .FirstAsync(x => x.Id == bookingId, ct);
        var maxReschedules = await GetIntConfigAsync("booking_reschedule_max", 2, ct);
        return new BookingDetailDto(
            b.Id, b.BookingNumber, b.Status.ToString(),
            b.ScheduledDate, b.ScheduledTime?.ToString("HH:mm"), b.SlotId,
            b.PatientName, b.ItemsTotal, b.DiscountTotal,
            b.WalletApplied, b.AmountPayable,
            b.RescheduleCount, maxReschedules,
            (b.Payment?.Status ?? PaymentStatus.Created).ToString(),
            (b.Payment?.Method ?? PaymentMethod.Upi).ToString(),
            b.Payment?.PaidAt,
            b.Items.Select(i => new BookingItemDto(i.ItemName, i.Mrp, i.Price)).ToList());
    }

    public async Task AssignTechnicianAsync(Guid bookingId, Guid technicianId, CancellationToken ct = default)
    {
        var booking = await _db.Set<Booking>().FirstOrDefaultAsync(b => b.Id == bookingId, ct)
            ?? throw new NotFoundAppException();
        if (booking.Status is not (BookingStatus.Confirmed or BookingStatus.Rescheduled))
            throw new ConflictAppException($"Cannot assign a technician to a {booking.Status} booking.");
        if (!await _db.Set<Technician>().AnyAsync(t => t.Id == technicianId && t.IsActive, ct))
            throw new ValidationAppException(new[] { new ApiError { Field = "technicianId", Message = "Unknown or inactive technician" } });

        booking.TechnicianId = technicianId;
        // A rescheduled booking re-enters the normal flow once ops re-vets the
        // assignment — keeps the technician state machine single-path.
        if (booking.Status == BookingStatus.Rescheduled)
            booking.Status = BookingStatus.Confirmed;
        booking.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        await PublishStatusAsync(booking, null, ct);
    }

    public async Task<IReadOnlyList<Booking>> ListAsync(Guid userId, string role, Guid? partnerId, CancellationToken ct = default)
    {
        var query = _db.Set<Booking>().AsNoTracking().AsQueryable();
        query = role switch
        {
            "partner" => query.Where(b => b.PartnerId == partnerId),
            "technician" => query.Where(b => b.TechnicianId == userId),
            "super_admin" or "admin" or "operations" or "lab" or "finance" or "support" => query,
            _ => query.Where(b => b.UserId == userId),
        };
        return await query.OrderByDescending(b => b.CreatedAt).Take(200).ToListAsync(ct);
    }

    public async Task CancelAsync(Guid userId, Guid bookingId, string? reason, CancellationToken ct = default)
    {
        var booking = await _db.Set<Booking>().FirstOrDefaultAsync(b => b.Id == bookingId, ct)
            ?? throw new NotFoundAppException();
        if (booking.UserId != userId) throw new ForbiddenAppException();

        var cancelWindowHours = await GetIntConfigAsync("booking_cancel_window_hours", 4, ct);
        if (booking.ScheduledDate.ToDateTime(booking.ScheduledTime ?? TimeOnly.MinValue)
            < DateTime.UtcNow.AddHours(cancelWindowHours))
            throw new ConflictAppException("Cancellation window has passed");

        booking.Status = BookingStatus.Cancelled;
        booking.CancellationReason = reason;
        booking.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        await PublishStatusAsync(booking, null, ct);
    }

    public async Task<BookingDetailDto> RescheduleAsync(Guid userId, Guid bookingId, RescheduleBookingRequest req, CancellationToken ct = default)
    {
        var booking = await _db.Set<Booking>().FirstOrDefaultAsync(b => b.Id == bookingId, ct)
            ?? throw new NotFoundAppException();
        if (booking.UserId != userId) throw new ForbiddenAppException();

        if (booking.Status is not (BookingStatus.Confirmed or BookingStatus.TechnicianAssigned or BookingStatus.Rescheduled))
            throw new ConflictAppException($"A {booking.Status} booking cannot be rescheduled.");

        var windowHours = await GetIntConfigAsync("booking_reschedule_window_hours", 4, ct);
        if (booking.ScheduledDate.ToDateTime(booking.ScheduledTime ?? TimeOnly.MinValue)
            < DateTime.UtcNow.AddHours(windowHours))
            throw new ConflictAppException("Reschedule window has passed");

        var maxReschedules = await GetIntConfigAsync("booking_reschedule_max", 2, ct);
        if (booking.RescheduleCount >= maxReschedules)
            throw new ConflictAppException("Reschedule limit reached");

        // Slot swap: reserve the new seat FIRST (atomic — can fail), then release
        // the old one (never fails). Same non-transactional trade-off as CreateAsync.
        TimeOnly? newSlotStart = null;
        if (req.SlotId is Guid newSlotId && newSlotId != booking.SlotId)
        {
            var newSlot = await _db.Set<Slot>().AsNoTracking().FirstOrDefaultAsync(s => s.Id == newSlotId, ct);
            if (newSlot is null || !await _db.TryReserveSlotSeatAsync(newSlotId, ct))
                throw new ValidationAppException(new[] { new ApiError { Field = "slotId", Message = "Slot is no longer available" } });
            newSlotStart = newSlot.StartTime;
            if (booking.SlotId is Guid oldSlotId)
                await _db.ReleaseSlotSeatAsync(oldSlotId, ct);
            booking.SlotId = newSlotId;
        }

        booking.ScheduledDate = req.ScheduledDate;
        booking.ScheduledTime = req.ScheduledTime ?? newSlotStart ?? booking.ScheduledTime;
        booking.RescheduleCount += 1;
        booking.Status = BookingStatus.Rescheduled;
        // The old technician's route is stale for the new time — ops re-assigns
        // (AssignTechnicianAsync normalizes Rescheduled → Confirmed).
        booking.TechnicianId = null;
        booking.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(ct);
        await PublishStatusAsync(booking, null, ct);

        return await GetAsync(userId, "customer", null, bookingId, ct);
    }

    public async Task<PagedResult<AdminBookingDto>> AdminListAsync(BookingStatus? status, PageRequest page, CancellationToken ct = default)
    {
        var query = _db.Set<Booking>().AsNoTracking();
        if (status is { } s) query = query.Where(b => b.Status == s);

        var total = await query.CountAsync(ct);
        var rows = await query
            .OrderByDescending(b => b.CreatedAt)
            .Skip(page.Skip).Take(page.PageSize)
            .Select(b => new
            {
                b.Id, b.BookingNumber, b.Status, b.ScheduledDate, b.ScheduledTime,
                b.AmountPayable, b.TechnicianId, b.CreatedAt, Mobile = b.User.Mobile,
            })
            .ToListAsync(ct);

        var items = rows.Select(b => new AdminBookingDto(
            b.Id, b.BookingNumber, _mask.MaskPhone(b.Mobile), b.Status.ToString(),
            b.ScheduledDate, b.ScheduledTime?.ToString("HH:mm"), b.AmountPayable,
            b.TechnicianId != null, b.CreatedAt)).ToList();

        return new PagedResult<AdminBookingDto> { Items = items, Total = total, Page = page.Page, PageSize = page.PageSize };
    }

    private async Task<int> GetIntConfigAsync(string key, int fallback, CancellationToken ct)
    {
        var raw = await _db.Set<AppConfig>().Where(c => c.Key == key).Select(c => c.Value).FirstOrDefaultAsync(ct);
        return int.TryParse(raw, out var v) ? v : fallback;
    }
}
