using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.Data;

// Full inferred schema across the 9 schemas from Section 2:
// core, catalogue, booking, reports, health, commerce, comms, content, admin.
public class AppDbContext : DbContext, IAppDbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public async Task<bool> TryReserveSlotSeatAsync(Guid slotId, CancellationToken ct = default)
    {
        if (Database.IsRelational())
        {
            var reserved = await Set<Slot>()
                .Where(s => s.Id == slotId && s.IsAvailable && s.Booked < s.Capacity)
                .ExecuteUpdateAsync(u => u.SetProperty(s => s.Booked, s => s.Booked + 1), ct);
            return reserved > 0;
        }
        // InMemory (tests): ExecuteUpdateAsync is relational-only; same guards, tracked write.
        var slot = await Set<Slot>().FirstOrDefaultAsync(s => s.Id == slotId, ct);
        if (slot is null || !slot.IsAvailable || slot.Booked >= slot.Capacity) return false;
        slot.Booked += 1;
        await SaveChangesAsync(ct);
        return true;
    }

    public async Task ReleaseSlotSeatAsync(Guid slotId, CancellationToken ct = default)
    {
        if (Database.IsRelational())
        {
            await Set<Slot>()
                .Where(s => s.Id == slotId && s.Booked > 0)
                .ExecuteUpdateAsync(u => u.SetProperty(s => s.Booked, s => s.Booked - 1), ct);
            return;
        }
        var slot = await Set<Slot>().FirstOrDefaultAsync(s => s.Id == slotId, ct);
        if (slot is null || slot.Booked <= 0) return;
        slot.Booked -= 1;
        await SaveChangesAsync(ct);
    }

    // ── core ──
    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<SecurityEvent> SecurityEvents => Set<SecurityEvent>();
    public DbSet<FamilyMember> FamilyMembers => Set<FamilyMember>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<AppConfig> AppConfigs => Set<AppConfig>();
    public DbSet<Device> Devices => Set<Device>();
    public DbSet<OtpRequest> OtpRequests => Set<OtpRequest>();

    // ── catalogue ──
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Specialty> Specialties => Set<Specialty>();
    public DbSet<Test> Tests => Set<Test>();
    public DbSet<TestParameter> TestParameters => Set<TestParameter>();
    public DbSet<TestFaq> TestFaqs => Set<TestFaq>();
    public DbSet<TestReview> TestReviews => Set<TestReview>();
    public DbSet<Package> Packages => Set<Package>();
    public DbSet<PackageTest> PackageTests => Set<PackageTest>();
    public DbSet<PackageCategory> PackageCategories => Set<PackageCategory>();
    public DbSet<TestCategory> TestCategories => Set<TestCategory>();
    public DbSet<Centre> Centres => Set<Centre>();
    public DbSet<CentrePricing> CentrePricings => Set<CentrePricing>();
    public DbSet<Doctor> Doctors => Set<Doctor>();
    public DbSet<DoctorSlot> DoctorSlots => Set<DoctorSlot>();
    public DbSet<Supplement> Supplements => Set<Supplement>();

    // ── booking ──
    public DbSet<Slot> Slots => Set<Slot>();
    public DbSet<Technician> Technicians => Set<Technician>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<BookingItem> BookingItems => Set<BookingItem>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<GroupBooking> GroupBookings => Set<GroupBooking>();
    public DbSet<GroupBookingMember> GroupBookingMembers => Set<GroupBookingMember>();
    public DbSet<CustomPackage> CustomPackages => Set<CustomPackage>();

    // ── reports ──
    public DbSet<LabReport> LabReports => Set<LabReport>();
    public DbSet<ReportParameter> ReportParameters => Set<ReportParameter>();
    public DbSet<DietPlan> DietPlans => Set<DietPlan>();
    public DbSet<Consultation> Consultations => Set<Consultation>();

    // ── health ──
    public DbSet<HealthScore> HealthScores => Set<HealthScore>();
    public DbSet<LifestyleLog> LifestyleLogs => Set<LifestyleLog>();
    public DbSet<Vital> Vitals => Set<Vital>();
    public DbSet<StepEntry> Steps => Set<StepEntry>();
    public DbSet<Reminder> Reminders => Set<Reminder>();
    public DbSet<SymptomCheck> SymptomChecks => Set<SymptomCheck>();

    // ── commerce ──
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Coupon> Coupons => Set<Coupon>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<Refund> Refunds => Set<Refund>();
    public DbSet<CashbackOffer> CashbackOffers => Set<CashbackOffer>();
    public DbSet<Cashback> Cashbacks => Set<Cashback>();
    public DbSet<MembershipTier> MembershipTiers => Set<MembershipTier>();
    public DbSet<Referral> Referrals => Set<Referral>();

    // ── comms ──
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AiSession> AiSessions => Set<AiSession>();
    public DbSet<AiChatMessage> AiChatMessages => Set<AiChatMessage>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<SupportMessage> SupportMessages => Set<SupportMessage>();
    public DbSet<WhatsAppTemplate> WhatsAppTemplates => Set<WhatsAppTemplate>();

    // ── content ──
    public DbSet<HomeSection> HomeSections => Set<HomeSection>();
    public DbSet<QuickAction> QuickActions => Set<QuickAction>();
    public DbSet<NavItem> NavItems => Set<NavItem>();
    public DbSet<OnboardingSlide> OnboardingSlides => Set<OnboardingSlide>();
    public DbSet<Banner> Banners => Set<Banner>();
    public DbSet<Article> Articles => Set<Article>();
    public DbSet<AiPrompt> AiPrompts => Set<AiPrompt>();

    // ── admin ──
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Partner> Partners => Set<Partner>();
    public DbSet<PartnerCommission> PartnerCommissions => Set<PartnerCommission>();

    // Entity → (table, schema). The explicit configs (UserConfiguration etc.) own
    // their tables; the rest are mapped here by convention.
    private static readonly Dictionary<Type, (string Table, string Schema)> TableMap = new()
    {
        [typeof(FamilyMember)] = ("family_members", "core"),
        [typeof(Address)] = ("addresses", "core"),
        [typeof(AuditLog)] = ("audit_logs", "core"),
        [typeof(AppConfig)] = ("app_config", "core"),
        [typeof(Device)] = ("devices", "core"),
        [typeof(OtpRequest)] = ("otp_requests", "core"),

        [typeof(Category)] = ("categories", "catalogue"),
        [typeof(Specialty)] = ("specialties", "catalogue"),
        [typeof(Test)] = ("tests", "catalogue"),
        [typeof(TestParameter)] = ("test_parameters", "catalogue"),
        [typeof(TestFaq)] = ("test_faqs", "catalogue"),
        [typeof(TestReview)] = ("test_reviews", "catalogue"),
        [typeof(Package)] = ("packages", "catalogue"),
        [typeof(PackageTest)] = ("package_tests", "catalogue"),
        [typeof(PackageCategory)] = ("package_categories", "catalogue"),
        [typeof(TestCategory)] = ("test_categories", "catalogue"),
        [typeof(Centre)] = ("centres", "catalogue"),
        [typeof(CentrePricing)] = ("centre_pricing", "catalogue"),
        [typeof(Doctor)] = ("doctors", "catalogue"),
        [typeof(DoctorSlot)] = ("doctor_slots", "catalogue"),
        [typeof(Supplement)] = ("supplements", "catalogue"),

        [typeof(Slot)] = ("slots", "booking"),
        [typeof(Technician)] = ("technicians", "booking"),
        [typeof(Booking)] = ("bookings", "booking"),
        [typeof(BookingItem)] = ("booking_items", "booking"),
        [typeof(Subscription)] = ("subscriptions", "booking"),
        [typeof(GroupBooking)] = ("group_bookings", "booking"),
        [typeof(GroupBookingMember)] = ("group_booking_members", "booking"),
        [typeof(CustomPackage)] = ("custom_packages", "booking"),

        [typeof(LabReport)] = ("lab_reports", "reports"),
        [typeof(ReportParameter)] = ("report_parameters", "reports"),
        [typeof(DietPlan)] = ("diet_plans", "reports"),
        [typeof(Consultation)] = ("consultations", "reports"),

        [typeof(HealthScore)] = ("health_scores", "health"),
        [typeof(LifestyleLog)] = ("lifestyle_logs", "health"),
        [typeof(Vital)] = ("vitals", "health"),
        [typeof(StepEntry)] = ("steps", "health"),
        [typeof(Reminder)] = ("reminders", "health"),
        [typeof(SymptomCheck)] = ("symptom_checks", "health"),

        [typeof(Cart)] = ("carts", "commerce"),
        [typeof(CartItem)] = ("cart_items", "commerce"),
        [typeof(Coupon)] = ("coupons", "commerce"),
        [typeof(Payment)] = ("payments", "commerce"),
        [typeof(Wallet)] = ("wallets", "commerce"),
        [typeof(WalletTransaction)] = ("wallet_transactions", "commerce"),
        [typeof(Refund)] = ("refunds", "commerce"),
        [typeof(CashbackOffer)] = ("cashback_offers", "commerce"),
        [typeof(Cashback)] = ("cashbacks", "commerce"),
        [typeof(MembershipTier)] = ("membership_tiers", "commerce"),
        [typeof(Referral)] = ("referrals", "commerce"),

        [typeof(Notification)] = ("notifications", "comms"),
        [typeof(AiSession)] = ("ai_sessions", "comms"),
        [typeof(AiChatMessage)] = ("ai_chat_messages", "comms"),
        [typeof(SupportTicket)] = ("support_tickets", "comms"),
        [typeof(SupportMessage)] = ("support_messages", "comms"),
        [typeof(WhatsAppTemplate)] = ("whatsapp_templates", "comms"),

        [typeof(HomeSection)] = ("home_sections", "content"),
        [typeof(QuickAction)] = ("quick_actions", "content"),
        [typeof(NavItem)] = ("nav_items", "content"),
        [typeof(OnboardingSlide)] = ("onboarding_slides", "content"),
        [typeof(Banner)] = ("banners", "content"),
        [typeof(Article)] = ("articles", "content"),
        [typeof(AiPrompt)] = ("ai_prompts", "content"),

        [typeof(Partner)] = ("partners", "admin"),
        [typeof(PartnerCommission)] = ("partner_commissions", "admin"),
    };

    // Unique indexes (slugs, codes, keys).
    private static readonly (Type Type, string Property)[] UniqueIndexes =
    {
        (typeof(Category), nameof(Category.Slug)),
        (typeof(Specialty), nameof(Specialty.Slug)),
        (typeof(Test), nameof(Test.Slug)),
        (typeof(Package), nameof(Package.Slug)),
        (typeof(Doctor), nameof(Doctor.Slug)),
        (typeof(Supplement), nameof(Supplement.Slug)),
        (typeof(Article), nameof(Article.Slug)),
        (typeof(Booking), nameof(Booking.BookingNumber)),
        (typeof(GroupBooking), nameof(GroupBooking.Code)),
        (typeof(Coupon), nameof(Coupon.Code)),
        (typeof(SupportTicket), nameof(SupportTicket.TicketNumber)),
        (typeof(AppConfig), nameof(AppConfig.Key)),
        (typeof(WhatsAppTemplate), nameof(WhatsAppTemplate.Key)),
        (typeof(Technician), nameof(Technician.EmployeeId)),
    };

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 1) Table + schema mapping for convention-configured entities.
        foreach (var (clr, map) in TableMap)
            modelBuilder.Entity(clr).ToTable(map.Table, map.Schema);

        // 2) Explicit configurations (own their tables; applied last so they win).
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // 3) Conventions applied across the whole model.
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var prop in entity.GetProperties())
            {
                var clrType = prop.ClrType;
                var underlying = Nullable.GetUnderlyingType(clrType) ?? clrType;

                // 3a) Store enums as strings (skip ones with an explicit converter).
                if (underlying.IsEnum && prop.GetValueConverter() is null)
                {
                    modelBuilder.Entity(entity.ClrType)
                        .Property(prop.Name).HasConversion<string>().HasMaxLength(40);
                }

                // 3b) created_at defaults to now() unless explicitly set.
                if (prop.Name == "CreatedAt"
                    && underlying == typeof(DateTimeOffset)
                    && prop.GetDefaultValueSql() is null)
                {
                    modelBuilder.Entity(entity.ClrType)
                        .Property(prop.Name).HasDefaultValueSql("now()");
                }
            }
        }

        // 4) Unique indexes.
        foreach (var (type, property) in UniqueIndexes)
            modelBuilder.Entity(type).HasIndex(property).IsUnique();

        // 5) Audit logs are immutable — no tracking-driven updates expected.
        modelBuilder.Entity<AuditLog>().Property(x => x.OldValues).HasColumnType("jsonb");
        modelBuilder.Entity<AuditLog>().Property(x => x.NewValues).HasColumnType("jsonb");

        // 6) Package ↔ Category join: composite key + FK to the package nav.
        modelBuilder.Entity<PackageCategory>().HasKey(pc => new { pc.PackageId, pc.CategoryId });
        modelBuilder.Entity<PackageCategory>()
            .HasOne<Package>()
            .WithMany(p => p.PackageCategories)
            .HasForeignKey(pc => pc.PackageId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<TestCategory>().HasKey(tc => new { tc.TestId, tc.CategoryId });
        modelBuilder.Entity<TestCategory>()
            .HasOne<Test>()
            .WithMany(t => t.TestCategories)
            .HasForeignKey(tc => tc.TestId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
