using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// catalogue.categories — test/package/concern/risk/specialty tabs (all from DB).
public class Category
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;           // UNIQUE
    public CatalogueCategoryType Type { get; set; }
    public string? IconUrl { get; set; }
    public string? Tag { get; set; }                    // concern/risk tag filter
    public bool ShowInFilter { get; set; } = true;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}

// catalogue.specialties — doctor specialties.
public class Specialty
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string? IconUrl { get; set; }
    public bool ShowInFilter { get; set; } = true;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}

// catalogue.tests.
public class Test
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;           // UNIQUE
    public string? ShortDescription { get; set; }
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Mrp { get; set; }
    public decimal Price { get; set; }
    public int ParameterCount { get; set; }
    public string? SampleType { get; set; }             // blood, urine...
    public bool FastingRequired { get; set; }
    public string? ReportTimeText { get; set; }         // "within 24 hrs"
    public bool HomeCollectionAvailable { get; set; } = true;
    public bool IsPopular { get; set; }
    public string? ConcernTags { get; set; }            // CSV/JSON tags
    public string? RiskTags { get; set; }
    public double RatingAverage { get; set; }
    public int RatingCount { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }

    public Category? Category { get; set; }
    public ICollection<TestParameter> Parameters { get; set; } = new List<TestParameter>();
    // Many-to-many browse categories (Heart / Liver / Diabetes…). Drives the
    // organ/concern/persona rails' category landing pages.
    public ICollection<TestCategory> TestCategories { get; set; } = new List<TestCategory>();
}

// Join: a test ↔ a browse category (Organ/Concern/Persona/…). Composite PK
// (no ValueGeneratedOnAdd Id — avoids EF's stale-UPDATE concurrency trap).
public class TestCategory
{
    public Guid TestId { get; set; }
    public Guid CategoryId { get; set; }
}

// catalogue.test_parameters.
public class TestParameter
{
    public Guid Id { get; set; }
    public Guid TestId { get; set; }
    public string Name { get; set; } = null!;
    public string? Unit { get; set; }
    public string? ReferenceRange { get; set; }
    public string? Description { get; set; }
    public int SortOrder { get; set; }

    public Test Test { get; set; } = null!;
}

// catalogue.test_faqs.
public class TestFaq
{
    public Guid Id { get; set; }
    public Guid TestId { get; set; }
    public string Question { get; set; } = null!;
    public string Answer { get; set; } = null!;
    public int SortOrder { get; set; }
}

// catalogue.test_reviews.
public class TestReview
{
    public Guid Id { get; set; }
    public Guid TestId { get; set; }
    public Guid? UserId { get; set; }
    public string? AuthorName { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public bool IsApproved { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

// catalogue.packages.
public class Package
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;           // UNIQUE
    public string? ShortDescription { get; set; }
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Mrp { get; set; }
    public decimal Price { get; set; }
    public int TestCount { get; set; }
    public int ParameterCount { get; set; }
    public bool FastingRequired { get; set; }
    public string? ReportTimeText { get; set; }
    // Rich package-detail content (Section 11) — all optional, admin-editable,
    // surfaced on the app's Package detail screen; a null/empty value hides the
    // corresponding section rather than showing a placeholder.
    public int? FastingHours { get; set; }          // e.g. 10 → "10–12 hrs fasting"
    public string? SampleType { get; set; }         // e.g. "Blood", "Blood, Urine"
    public string? Preparation { get; set; }         // how-to-prepare instructions
    public string? RecommendedFor { get; set; }      // who should take this
    public string? FaqJson { get; set; }             // [{"q":"…","a":"…"}] JSON
    public bool IsPopular { get; set; }
    public bool IsFeatured { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<PackageTest> PackageTests { get; set; } = new List<PackageTest>();
    // Many-to-many category tags (Full Body / Diabetes / Heart / Women…). Drives
    // the home filter chips; a package can belong to several categories.
    public ICollection<PackageCategory> PackageCategories { get; set; } = new List<PackageCategory>();
}

// Join: a package ↔ a catalogue category (Type = Package). Composite PK.
public class PackageCategory
{
    public Guid PackageId { get; set; }
    public Guid CategoryId { get; set; }
}

// catalogue.package_tests (join).
public class PackageTest
{
    public Guid Id { get; set; }
    public Guid PackageId { get; set; }
    public Guid TestId { get; set; }

    public Package Package { get; set; } = null!;
    public Test Test { get; set; } = null!;
}

// catalogue.centres — collection / diagnostic centres.
public class Centre
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string? AddressLine { get; set; }
    public string City { get; set; } = null!;
    public string State { get; set; } = null!;
    public string Pincode { get; set; } = null!;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Phone { get; set; }
    public string? OpenHours { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}

// catalogue.centre_pricing — per-centre test/package price overrides.
public class CentrePricing
{
    public Guid Id { get; set; }
    public Guid CentreId { get; set; }
    public Guid? TestId { get; set; }
    public Guid? PackageId { get; set; }
    public decimal Price { get; set; }
}

// catalogue.doctors.
public class Doctor
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public Guid? SpecialtyId { get; set; }
    public string? Qualification { get; set; }
    public int ExperienceYears { get; set; }
    public string? PhotoUrl { get; set; }
    public string? About { get; set; }
    public decimal ConsultationFee { get; set; }
    public string? Languages { get; set; }
    public double RatingAverage { get; set; }
    public int RatingCount { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }

    public Specialty? Specialty { get; set; }
}

// catalogue.doctor_slots.
public class DoctorSlot
{
    public Guid Id { get; set; }
    public Guid DoctorId { get; set; }
    public DateOnly Date { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public int Capacity { get; set; } = 1;
    public int Booked { get; set; }
    public bool IsAvailable { get; set; } = true;
}

// catalogue.supplements.
public class Supplement
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal Mrp { get; set; }
    public decimal Price { get; set; }
    public string? ForConcernTags { get; set; }         // matched to report findings
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}
