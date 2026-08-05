namespace Bit2sky.Domain.Enums;

public enum HomeSectionType
{
    Banner, CategoryGrid, QuickActions, PopularTests, FeaturedPackages, HealthScore, Articles, Supplements, Testimonials, Cashback, Custom,
    ActiveBooking, Recommended, FamilyHealth, Offers,
    // D2 home rebuild — append only, never reorder (values serialize by name but
    // may be persisted numerically elsewhere).
    PrescriptionUpload, CustomPackageBanner, PersonaPlans, OrganRail, ConcernRail, LifestyleRail, TrustBlock, ReferEarn
}
