using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// booking.slots — home-collection time slots per pincode/date.
public class Slot
{
    public Guid Id { get; set; }
    public DateOnly Date { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string? Pincode { get; set; }
    public Guid? CentreId { get; set; }
    public int Capacity { get; set; }
    public int Booked { get; set; }
    public bool IsAvailable { get; set; } = true;
}

// booking.technicians (app users; profile linked to core.users).
public class Technician
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }                    // linked login (carries 'technician' role)
    public string? EmployeeId { get; set; }              // login id, UNIQUE
    public string? PasswordHash { get; set; }            // bcrypt; app login
    public string Name { get; set; } = null!;
    public string Mobile { get; set; } = null!;
    public string? PhotoUrl { get; set; }
    public string? ServiceZones { get; set; }           // pincodes/zones (JSON/CSV)
    public TechnicianStatus Status { get; set; } = TechnicianStatus.Offline;
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public double RatingAverage { get; set; }
    public bool IsActive { get; set; } = true;
    public int FailedLoginCount { get; set; }
    public DateTimeOffset? LoginLockedUntil { get; set; }
    public DateTimeOffset? LastLoginAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User? User { get; set; }
}

// booking.bookings (PHI — strict ownership).
public class Booking
{
    public Guid Id { get; set; }
    public string BookingNumber { get; set; } = null!;   // UNIQUE human ref
    public Guid UserId { get; set; }
    public Guid? FamilyMemberId { get; set; }            // who the test is for
    // Patient snapshot at booking time — labs read age/sex from here, and it
    // stays accurate even if the family member is later edited or removed.
    public string? PatientName { get; set; }
    public Gender? PatientGender { get; set; }
    public DateOnly? PatientDateOfBirth { get; set; }
    public Guid? PartnerId { get; set; }                 // partner who created it
    public Guid? TechnicianId { get; set; }              // assigned technician
    public Guid? AddressId { get; set; }
    public Guid? SlotId { get; set; }
    public Guid? CentreId { get; set; }
    public SampleCollectionType CollectionType { get; set; } = SampleCollectionType.HomeCollection;
    public DateOnly ScheduledDate { get; set; }
    public TimeOnly? ScheduledTime { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Pending;
    public decimal ItemsTotal { get; set; }
    public decimal DiscountTotal { get; set; }
    public decimal WalletApplied { get; set; }
    public decimal AmountPayable { get; set; }
    public Guid? CouponId { get; set; }
    public int RescheduleCount { get; set; }
    public string? CancellationReason { get; set; }
    public string? SampleBarcode { get; set; }           // captured by technician at collection
    public string? CollectionPhotoUrl { get; set; }      // proof-of-collection photo
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<BookingItem> Items { get; set; } = new List<BookingItem>();
    public Payment? Payment { get; set; }
}

// booking.booking_items — tests/packages within a booking.
public class BookingItem
{
    public Guid Id { get; set; }
    public Guid BookingId { get; set; }
    public Guid? TestId { get; set; }
    public Guid? PackageId { get; set; }
    public string ItemName { get; set; } = null!;
    public decimal Mrp { get; set; }
    public decimal Price { get; set; }

    public Booking Booking { get; set; } = null!;
}

// booking.subscriptions — recurring test plans.
public class Subscription
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? PackageId { get; set; }
    public Guid? TestId { get; set; }
    public SubscriptionFrequency Frequency { get; set; }
    public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Active;
    public DateOnly StartDate { get; set; }
    public DateOnly? NextBookingDate { get; set; }
    public DateOnly? PausedUntil { get; set; }
    public decimal PricePerCycle { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}

// booking.group_bookings — shareable code, members join.
public class GroupBooking
{
    public Guid Id { get; set; }
    public string Code { get; set; } = null!;            // UNIQUE share code
    public Guid CreatedByUserId { get; set; }
    public Guid? PackageId { get; set; }
    public Guid? TestId { get; set; }
    public int MinMembers { get; set; }
    public int MaxMembers { get; set; }
    public decimal DiscountPercent { get; set; }
    public GroupBookingStatus Status { get; set; } = GroupBookingStatus.Open;
    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<GroupBookingMember> Members { get; set; } = new List<GroupBookingMember>();
}

// booking.group_booking_members.
public class GroupBookingMember
{
    public Guid Id { get; set; }
    public Guid GroupBookingId { get; set; }
    public Guid UserId { get; set; }
    public Guid? BookingId { get; set; }
    public DateTimeOffset JoinedAt { get; set; }

    public GroupBooking GroupBooking { get; set; } = null!;
}

// booking.custom_packages — user-built packages (discount from config).
public class CustomPackage
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = null!;
    public decimal Mrp { get; set; }
    public decimal Price { get; set; }                   // after config-driven discount
    public decimal DiscountPercent { get; set; }
    public string TestIds { get; set; } = null!;         // JSON array of test ids
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
