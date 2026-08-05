using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Infrastructure.Data;

// Idempotent seed for RBAC (Section 3A/3B) and security app_config (Section 17).
public static class DataSeeder
{
    // All permission codes from Section 3A.
    private static readonly string[] PermissionCodes =
    {
        "users.view","users.create","users.update","users.deactivate","users.export","users.view_pii","users.delete",
        "bookings.view","bookings.create","bookings.update","bookings.delete","bookings.assign_technician","bookings.cancel","bookings.reschedule","bookings.export",
        "tests.view","tests.create","tests.update","tests.delete",
        "packages.view","packages.create","packages.update","packages.delete",
        "categories.view","categories.create","categories.update","categories.delete",
        "specialties.view","specialties.create","specialties.update","specialties.delete",
        "reports.view","reports.upload","reports.update","reports.delete","reports.download","reports.export","reports.view_ai_summary",
        "doctors.view","doctors.create","doctors.update","doctors.delete",
        "centres.view","centres.create","centres.update","centres.delete",
        "consultations.view","consultations.manage",
        "technicians.view","technicians.create","technicians.update","technicians.delete","technicians.manage_zones",
        "payments.view","payments.refund","payments.export",
        "coupons.view","coupons.create","coupons.update","coupons.delete",
        "wallet.view","wallet.adjust",
        "membership.view","membership.update",
        "cashback.view","cashback.create","cashback.update",
        "refunds.view","refunds.process",
        "partners.view","partners.verify","partners.payout","partners.update",
        "content.view","content.create","content.update","content.delete",
        "banners.view","banners.create","banners.update","banners.delete",
        "articles.view","articles.create","articles.update","articles.delete",
        "home_layout.view","home_layout.update",
        "nav_items.view","nav_items.update",
        "onboarding.view","onboarding.update",
        "ai_prompts.view","ai_prompts.create","ai_prompts.activate",
        "whatsapp_templates.view","whatsapp_templates.update",
        "supplements.view","supplements.create","supplements.update","supplements.delete",
        "notifications.view","notifications.broadcast",
        "support.view","support.respond","support.assign","support.close",
        "analytics.view","analytics.export",
        "config.view","config.update",
        "roles.view","roles.create","roles.update","roles.delete",
        "audit_logs.view",
    };

    // Role → permission codes (Section 3B). super_admin and admin computed below.
    private static readonly Dictionary<string, string[]> RolePermissionMap = new()
    {
        ["operations"] = new[]
        {
            "bookings.view","bookings.update","bookings.assign_technician","bookings.cancel","bookings.reschedule",
            "technicians.view","technicians.manage_zones",
            "reports.view","reports.upload","reports.update",
            "users.view","notifications.view","analytics.view",
        },
        ["finance"] = new[]
        {
            "payments.view","payments.refund","payments.export",
            "coupons.view","coupons.create","coupons.update","coupons.delete",
            "wallet.view","wallet.adjust","membership.view","membership.update",
            "cashback.view","cashback.create","cashback.update",
            "refunds.view","refunds.process","partners.view","partners.payout",
            "analytics.view","analytics.export","bookings.view",
        },
        ["lab"] = new[]
        {
            "reports.view","reports.upload","reports.update","reports.download",
            "bookings.view","tests.view","packages.view",
        },
        ["content"] = new[]
        {
            "content.view","content.create","content.update","content.delete",
            "banners.view","banners.create","banners.update","banners.delete",
            "articles.view","articles.create","articles.update","articles.delete",
            "home_layout.view","home_layout.update","nav_items.view","nav_items.update",
            "onboarding.view","onboarding.update",
            "ai_prompts.view","ai_prompts.create","ai_prompts.activate",
            "whatsapp_templates.view","whatsapp_templates.update",
            "supplements.view","supplements.create","supplements.update","notifications.view",
        },
        ["support"] = new[]
        {
            "support.view","support.respond","support.assign","support.close",
            "users.view","bookings.view","reports.view","notifications.view",
        },
        // App roles — no admin-portal grants; their APIs authorize on role + ownership.
        ["technician"] = Array.Empty<string>(),
        ["partner"] = Array.Empty<string>(),
    };

    // Security app_config keys (Section 17).
    private static readonly (string Key, string Value)[] SecurityConfig =
    {
        ("admin_session_timeout_minutes","30"),
        ("admin_ip_allowlist_enabled","false"),
        ("otp_max_attempts","5"),
        ("otp_lockout_tier1_minutes","2"),
        ("otp_lockout_tier2_minutes","15"),
        ("otp_lockout_tier3_hours","24"),
        ("otp_expiry_minutes","5"),
        ("jwt_access_token_minutes","15"),
        ("jwt_refresh_token_days","30"),
        ("jwt_admin_refresh_hours","8"),
        ("rate_limit_ai_hourly","20"),
        ("rate_limit_otp_per_mobile_10min","3"),
        ("rate_limit_booking_per_min","10"),
        ("signed_url_expiry_minutes","15"),
        ("phi_cache_ttl_hours","24"),
        ("security_alert_email","security@bit2sky.com"),
        ("pentest_next_date","2026-01-01"),
    };

    // Default dev credentials — seeded only when a hasher is supplied. ROTATE in any
    // real environment (the super_admin still enrolls TOTP on first login).
    public const string DefaultAdminEmail = "admin@bit2sky.com";
    public const string DefaultAdminPassword = "Admin@12345";
    public const string DefaultTechEmployeeId = "TECH001";
    public const string DefaultTechPassword = "Tech@12345";
    public const string DefaultPartnerMobile = "+919000000003";

    public static async Task SeedAsync(AppDbContext db, IHashService? hasher = null, CancellationToken ct = default)
    {
        await SeedPermissionsAsync(db, ct);
        await SeedRolesAsync(db, ct);
        await SeedConfigAsync(db, ct);
        await SeedHomeContentAsync(db, ct);
        await SeedCatalogueAsync(db, ct);
        if (hasher is not null)
            await SeedDemoUsersAsync(db, hasher, ct);
        await db.SaveChangesAsync(ct);
    }

    // Premium onboarding slides + home services (Section 8). Content is DB-driven;
    // the apps fall back to equivalent defaults only when the API is unreachable.
    private static async Task SeedHomeContentAsync(AppDbContext db, CancellationToken ct)
    {
        if (!await db.Set<OnboardingSlide>().AnyAsync(ct))
        {
            db.Set<OnboardingSlide>().AddRange(
                new OnboardingSlide { Id = Guid.NewGuid(), SortOrder = 0, IsActive = true,
                    Title = "Book lab tests from your doorstep",
                    Subtitle = "Certified phlebotomists collect samples at home, at your convenience.",
                    ImageUrl = "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=900&q=80&auto=format&fit=crop" },
                new OnboardingSlide { Id = Guid.NewGuid(), SortOrder = 1, IsActive = true,
                    Title = "Understand your results with AI",
                    Subtitle = "Wellio explains every report parameter in plain language — not just numbers.",
                    ImageUrl = "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=900&q=80&auto=format&fit=crop" },
                new OnboardingSlide { Id = Guid.NewGuid(), SortOrder = 2, IsActive = true,
                    Title = "Track your health over time",
                    Subtitle = "One health score and clear trends that keep you ahead of your health.",
                    ImageUrl = "https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=900&q=80&auto=format&fit=crop" });
        }

        if (!await db.Set<QuickAction>().AnyAsync(ct))
        {
            var services = new (string Label, string Icon, string Link)[]
            {
                // Each service routes to its own destination. MRI/Doctor/Diet/
                // Vaccination/Corporate open their dedicated ServiceLandingScreen
                // (/services/:id) instead of all funnelling to /tests or /care.
                ("Blood Tests", "🩸", "/tests"),
                ("Full Body", "📦", "/packages"),
                ("MRI & Scans", "🧲", "/services/mri"),
                ("Doctor Consult", "👨‍⚕️", "/services/doctor"),
                ("Diet Consult", "🥗", "/services/diet"),
                ("Vaccination", "💉", "/services/vaccination"),
                ("Reports", "📄", "/reports"),
                ("Corporate", "🏢", "/services/corporate"),
            };
            for (var i = 0; i < services.Length; i++)
            {
                var s = services[i];
                db.Set<QuickAction>().Add(new QuickAction
                {
                    Id = Guid.NewGuid(), Label = s.Label, IconUrl = s.Icon,
                    DeepLink = s.Link, SortOrder = i, IsVisible = true,
                });
            }
        }

        if (!await db.Set<Banner>().AnyAsync(ct))
        {
            var banners = new (string Title, string Subtitle, string Cta, string Img, string Link)[]
            {
                ("Full Body Checkup", "89 tests at ₹1999 · Save 72%", "Book Now",
                 "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&q=80&auto=format&fit=crop", "/packages/full-health-checkup"),
                ("Free Home Collection", "On orders above ₹499", "Explore",
                 "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=900&q=80&auto=format&fit=crop", "/blood-tests"),
                ("Family Health Plans", "Cover up to 6 members", "View Plans",
                 "https://images.unsplash.com/photo-1511174511562-5f7f18b874f8?w=900&q=80&auto=format&fit=crop", "/packages"),
            };
            for (var i = 0; i < banners.Length; i++)
            {
                var b = banners[i];
                db.Set<Banner>().Add(new Banner
                {
                    Id = Guid.NewGuid(), Title = b.Title, Subtitle = b.Subtitle,
                    CtaLabel = b.Cta, ImageUrl = b.Img, DeepLink = b.Link,
                    SortOrder = i, IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
                });
            }
        }

        // Home layout — WHICH sections render and in what order (admin-reorderable).
        await SeedVersionedContentAsync(db, ct);
        await SeedArticlesAsync(db, ct);
    }

    // Catalogue — the tests + packages the app browses/recommends (Section 7).
    // ConcernTags feed the rule-based recommender (age/gender matching).
    private static async Task SeedCatalogueAsync(AppDbContext db, CancellationToken ct)
    {
        if (!await db.Set<Test>().AnyAsync(ct))
        {
            // Real price list (Doctor Price List 2026).
            var tests = new (string Name, decimal Price, string Sample, bool Fasting, bool Popular)[]
            {
                ("C.B.C.", 300, "EDTA 2 ML", false, true),
                ("C.B.C + MP", 350, "EDTA 2 ML", false, false),
                ("C.B.C + ESR", 400, "EDTA 2 ML", false, false),
                ("E.S.R.", 100, "EDTA 2 ML", false, false),
                ("Malarial Parasite [P.S.]", 100, "EDTA 2 ML", false, false),
                ("Malarial Antigen", 400, "EDTA 2 ML", false, false),
                ("Widal", 250, "PLAIN 2ML", false, false),
                ("S.Typhi IgM", 500, "PLAIN 2ML", false, false),
                ("Chikungunya", 850, "PLAIN 2ML", false, false),
                ("Dengue NS1", 600, "PLAIN 2ML", false, false),
                ("Dengue IgG IgM", 1200, "PLAIN 2ML", false, false),
                ("Blood Sugar F/PP", 100, "2 ml Sod Fluoride", true, true),
                ("RBS", 60, "2 ml Sod Fluoride", false, true),
                ("GTT [1 Sample]", 100, "2 ml Sod Fluoride", true, false),
                ("Sr.Cholesterol", 250, "SST Gel/Red Top", true, false),
                ("Sr.Triglyceride", 250, "SST Gel/Red Top", true, false),
                ("HDL Cholesterol", 250, "SST Gel/Red Top", true, false),
                ("Blood Urea", 250, "SST Gel/Red Top", false, false),
                ("Sr.Creatinine", 250, "SST Gel/Red Top", false, true),
                ("Sr.Uric Acid", 250, "SST Gel/Red Top", false, false),
                ("Sr.Calcium", 250, "SST Gel/Red Top", false, false),
                ("Sr.Electrolyte", 600, "SST Gel/Red Top", false, false),
                ("SGOT", 250, "SST Gel/Red Top", false, false),
                ("SGPT", 250, "SST Gel/Red Top", false, false),
                ("Alk.Phosphatase", 250, "SST Gel/Red Top", false, false),
                ("Total Protein (Alb + Glob.)", 400, "SST Gel/Red Top", false, false),
                ("Sr.Bilirubin [TDI]", 250, "SST Gel/Red Top", false, false),
                ("LDH", 700, "SST Gel/Red Top", false, false),
                ("GGT", 300, "SST Gel/Red Top", false, false),
                ("RA Factor", 500, "SST Gel/Red Top", false, false),
                ("CRP", 500, "SST Gel/Red Top", false, false),
                ("ASO [Quantitative]", 800, "SST Gel/Red Top", false, false),
                ("HsCRP", 800, "SST Gel/Red Top", false, false),
                ("Liver Profile (LFT)", 1000, "SST Gel/Red Top", false, true),
                ("Renal Profile (RFT)", 1200, "SST Gel/Red Top", false, false),
                ("ANC Profile + HCV", 1500, "SST Gel/Red Top/EDTA/Fluoride", false, false),
                ("ANC Profile + TFT", 2000, "SST Gel/Red Top/EDTA/Fluoride", false, false),
                ("HIV I & II", 500, "SST Gel/Red Top", false, false),
                ("HBsAg", 250, "SST Gel/Red Top", false, false),
                ("VDRL", 250, "SST Gel/Red Top", false, false),
                ("Anti HCV", 500, "SST Gel/Red Top", false, false),
                ("Mantoux Test", 250, "", false, false),
                ("AFB [Each Sample]", 250, "Sputum/Body fluids", false, false),
                ("Trop I", 1300, "SST Gel/Red Top", false, false),
                ("eGFR", 600, "SST Gel/Red Top", false, false),
                ("Stool Examination", 250, "Stool in container", false, false),
                ("Urine Examination", 150, "Urine in container", false, true),
                ("TSH", 350, "SST Gel/Red Top", false, true),
                ("T3 T4 TSH", 500, "SST Gel/Red Top", false, true),
                ("FT3 + FT4 + TSH", 750, "SST Gel/Red Top", false, false),
                ("FSH", 500, "SST Gel/Red Top", false, false),
                ("LH", 500, "SST Gel/Red Top", false, false),
                ("Prolactin", 500, "SST Gel/Red Top", false, false),
                ("Testosterone [Free]", 1500, "SST Gel/Red Top", false, false),
                ("Testosterone [Total]", 700, "SST Gel/Red Top", false, false),
                ("FSH + LH + Prolactin", 1250, "SST Gel/Red Top", false, false),
                ("FSH + LH + Prolactin + Testosterone", 1550, "SST Gel/Red Top", false, false),
                ("FSH + LH + Prolactin + TSH", 1500, "SST Gel/Red Top", false, false),
                ("AMH", 2100, "SST Gel/Red Top", false, false),
                ("Vitamin D3", 1200, "SST Gel/Red Top", false, true),
                ("Vitamin B12", 1000, "SST Gel/Red Top", false, true),
                ("Beta HCG", 750, "SST Gel/Red Top", false, false),
                ("CA 125", 1450, "SST Gel/Red Top", false, false),
                ("Ferritin", 800, "SST Gel/Red Top", false, false),
                ("AMA + ATG", 2200, "SST Gel/Red Top", false, false),
                ("HbA1c", 550, "EDTA 2 ML", false, true),
                ("Hb Electrophoresis", 1000, "EDTA 2 ML", false, false),
                ("PSA", 750, "SST Gel/Red Top", false, true),
                ("Cortisol", 900, "SST Gel/Red Top", false, false),
                ("TORCH 8", 2500, "SST Gel/Red Top", false, false),
                ("TORCH 10", 3500, "SST Gel/Red Top", false, false),
                ("Total IgE", 1000, "SST Gel/Red Top", false, false),
                ("Coombs Test Direct", 800, "EDTA 2 ML", false, false),
                ("Coombs Test Indirect", 800, "EDTA 2 ML", false, false),
                ("ADA", 1000, "SST Gel/Red Top", false, false),
                ("Iron Studies", 800, "SST Gel/Red Top", false, true),
                ("Histopath (Small)", 1500, "", false, false),
                ("Histopath (Medium)", 2500, "", false, false),
                ("Histopath (Large)", 3500, "", false, false),
                ("ACL IgG IgM [Each]", 1300, "SST Gel/Red Top", false, false),
                ("APL IgG IgM [Each]", 1300, "SST Gel/Red Top", false, false),
                ("Lupus Anticoagulant", 2000, "Sodium citrate", false, false),
                ("ACE", 1400, "SST Gel/Red Top", false, false),
                ("CEA", 1200, "SST Gel/Red Top", false, false),
                ("AFP", 1200, "SST Gel/Red Top", false, false),
                ("Homocysteine", 1600, "SST Gel/Red Top", false, false),
                ("Anti CCP", 1700, "SST Gel/Red Top", false, false),
                ("HLA B27", 2700, "EDTA 2 ML", false, false),
                ("ANA (Anti Nuclear Antibody)", 1000, "SST Gel/Red Top", false, false),
                ("Double Marker", 2500, "SST Gel/Red Top", false, false),
                ("Quadruple Marker", 3000, "SST Gel/Red Top", false, false),
                ("TB Gold", 3000, "Lithium heparin", false, false),
                ("GeneXpert", 3000, "Sputum/Body fluids", false, false),
                ("Urine Culture", 1000, "Urine in sterilised container", false, false),
                ("Blood Culture", 1200, "Whole Blood", false, false),
                ("Blood Culture (BACTEC)", 1500, "Blood in BACTEC culture bottle", false, false),
                ("Pus Culture", 1000, "Pus", false, false),
                ("Sputum Culture", 1000, "Sputum", false, false),
                ("Sputum AFB Culture", 1600, "Sputum", false, false),
            };
            foreach (var t in tests)
            {
                db.Set<Test>().Add(new Test
                {
                    Id = Guid.NewGuid(), Name = t.Name, Slug = Slugify(t.Name),
                    ParameterCount = 1, Price = t.Price, Mrp = t.Price,
                    ReportTimeText = "Report in 6 hours",
                    SampleType = t.Sample.Length == 0 ? null : t.Sample,
                    FastingRequired = t.Fasting, HomeCollectionAvailable = true,
                    IsPopular = t.Popular, RatingAverage = 0, RatingCount = 0,
                    IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
                });
            }
        }

        if (!await db.Set<Package>().AnyAsync(ct))
        {
            // Real poster packages.
            var packages = new (string Name, decimal Mrp, decimal Price, int Count,
                string Short, bool Pop, bool Feat, int FastingHours, string Rec)[]
            {
                ("Women Profile", 6500, 2499, 90, "Complete preventive check-up designed for women", true, true, 12, "women"),
                ("Men Profile", 7000, 2499, 90, "Complete preventive check-up designed for men", true, true, 12, "men"),
                ("Diabetes Profile", 2250, 1450, 35, "Track and manage diabetes with the essentials", true, false, 12, "diabetes"),
                ("Cardiac Profile", 6700, 3200, 35, "Heart health screening with HsCRP and vitamins", true, false, 12, "heart"),
                ("Arthritis Profile", 6400, 3000, 32, "Joint pain and inflammation work-up", false, false, 0, "arthritis,joint-pain"),
                ("Mini Fever Profile", 1650, 1150, 8, "Essential fever panel", false, false, 0, "fever"),
                ("Maxi Fever Profile", 3600, 2450, 12, "Comprehensive fever panel", false, false, 0, "fever"),
                ("Men Cancer Marker", 8240, 2899, 5, "Early-detection cancer markers for men", false, false, 0, "men,cancer-screening"),
                ("Women Cancer Marker", 3600, 3499, 5, "Early-detection cancer markers for women", false, false, 0, "women,cancer-screening"),
                ("Full Health Checkup", 7110, 1999, 89, "Preventive health package — 89 tests at home", true, true, 12, "full-body"),
            };
            foreach (var pk in packages)
            {
                db.Set<Package>().Add(new Package
                {
                    Id = Guid.NewGuid(), Name = pk.Name, Slug = Slugify(pk.Name),
                    ShortDescription = pk.Short, TestCount = pk.Count,
                    ParameterCount = pk.Count, Price = pk.Price, Mrp = pk.Mrp,
                    ReportTimeText = "Report in 6 hours",
                    FastingRequired = pk.FastingHours > 0,
                    FastingHours = pk.FastingHours > 0 ? pk.FastingHours : null,
                    RecommendedFor = pk.Rec, IsPopular = pk.Pop, IsFeatured = pk.Feat,
                    IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
                });
            }
        }
        if (!await db.Set<Coupon>().AnyAsync(ct))
        {
            db.Set<Coupon>().AddRange(
                new Coupon { Id = Guid.NewGuid(), Code = "WELCOME200", Type = CouponType.Flat,
                    Value = 200, MinOrderValue = 999, PerUserLimit = 1, IsActive = true,
                    Description = "₹200 off on your first booking above ₹999",
                    CreatedAt = DateTimeOffset.UtcNow },
                new Coupon { Id = Guid.NewGuid(), Code = "FULLBODY10", Type = CouponType.Percentage,
                    Value = 10, MaxDiscount = 300, MinOrderValue = 1499, PerUserLimit = 1,
                    IsActive = true,
                    Description = "Extra 10% off (up to ₹300) on orders above ₹1,499",
                    CreatedAt = DateTimeOffset.UtcNow },
                new Coupon { Id = Guid.NewGuid(), Code = "FAMILY500", Type = CouponType.Flat,
                    Value = 500, MinOrderValue = 4000, PerUserLimit = 1, IsActive = true,
                    Description = "₹500 off on orders above ₹4,000",
                    CreatedAt = DateTimeOffset.UtcNow });
        }

        if (!await db.Set<AppConfig>().AnyAsync(c => c.Key == "group_discount_tiers", ct))
        {
            db.Set<AppConfig>().Add(new AppConfig
            {
                Id = Guid.NewGuid(), Key = "group_discount_tiers", Value = "0,15,20,25",
                ValueType = "string", Category = "feature", IsPublic = true,
                Description = "% off per person for same package × N members (1..4+)",
                UpdatedAt = DateTimeOffset.UtcNow,
            });
        }

        await db.SaveChangesAsync(ct);

        await SeedPackageCategoriesAsync(db, ct);
        await SeedPackageTestsAsync(db, ct);
        await SeedBrowseCategoriesAsync(db, ct);
    }

    // Organ / Concern / Persona browse categories (behind the home rails) + a demo
    // mapping of tests and packages onto them, so tapping "Heart" / "Diabetes" /
    // "Women's Care" opens a real filtered landing page. Admins manage these in the
    // portal afterward. Idempotent: seeds only if no Organ category exists yet.
    private static async Task SeedBrowseCategoriesAsync(AppDbContext db, CancellationToken ct)
    {
        if (await db.Set<Category>().AnyAsync(c => c.Type == CatalogueCategoryType.Organ, ct)) return;

        // (Name, slug, type, icon, tests it tags, packages it tags)
        var defs = new (string Name, string Slug, CatalogueCategoryType Type, string Icon,
            string[] Tests, string[] Packages)[]
        {
            ("Heart", "organ-heart", CatalogueCategoryType.Organ, "favorite",
                new[] { "sr-cholesterol", "hdl-cholesterol", "hscrp", "trop-i" }, new[] { "cardiac-profile" }),
            ("Liver", "organ-liver", CatalogueCategoryType.Organ, "science",
                new[] { "liver-profile-lft", "sgot", "sgpt" }, System.Array.Empty<string>()),
            ("Kidney", "organ-kidney", CatalogueCategoryType.Organ, "water_drop",
                new[] { "renal-profile-rft", "sr-creatinine", "egfr" }, System.Array.Empty<string>()),
            ("Thyroid", "organ-thyroid", CatalogueCategoryType.Organ, "health_and_safety",
                new[] { "tsh", "t3-t4-tsh", "ft3-ft4-tsh" }, System.Array.Empty<string>()),
            ("Diabetes", "concern-diabetes", CatalogueCategoryType.Concern, "monitor_heart",
                new[] { "hba1c", "blood-sugar-f-pp", "gtt-1-sample" }, new[] { "diabetes-profile" }),
            ("Anemia", "concern-anemia", CatalogueCategoryType.Concern, "bloodtype",
                new[] { "iron-studies", "c-b-c", "hb-electrophoresis", "ferritin" }, System.Array.Empty<string>()),
            ("Heart Health", "concern-heart-health", CatalogueCategoryType.Concern, "favorite",
                new[] { "hscrp", "sr-cholesterol", "trop-i" }, new[] { "cardiac-profile" }),
            ("Vitamins", "concern-vitamins", CatalogueCategoryType.Concern, "wb_sunny",
                new[] { "vitamin-d3", "vitamin-b12" }, System.Array.Empty<string>()),
            ("Women's Care", "persona-women", CatalogueCategoryType.Persona, "female",
                new[] { "c-b-c", "t3-t4-tsh", "iron-studies", "ca-125", "amh" },
                new[] { "women-profile", "women-cancer-marker" }),
            ("Men's Care", "persona-men", CatalogueCategoryType.Persona, "male",
                new[] { "psa", "testosterone-total", "hba1c" }, new[] { "men-profile", "men-cancer-marker" }),
            ("Elderly Care", "persona-elderly", CatalogueCategoryType.Persona, "elderly",
                new[] { "renal-profile-rft", "t3-t4-tsh", "sr-uric-acid" },
                new[] { "arthritis-profile", "full-health-checkup" }),
        };

        var testBySlug = (await db.Set<Test>().AsNoTracking()
            .Select(t => new { t.Id, t.Slug }).ToListAsync(ct))
            .ToDictionary(t => t.Slug, t => t.Id);
        var pkgBySlug = (await db.Set<Package>().AsNoTracking()
            .Select(p => new { p.Id, p.Slug }).ToListAsync(ct))
            .ToDictionary(p => p.Slug, p => p.Id);

        var sort = 0;
        var cidBySlug = new Dictionary<string, Guid>();
        var taggedTests = new HashSet<(Guid, Guid)>();
        foreach (var d in defs)
        {
            var cid = Guid.NewGuid();
            cidBySlug[d.Slug] = cid;
            db.Set<Category>().Add(new Category
            {
                Id = cid, Name = d.Name, Slug = d.Slug, Type = d.Type, IconUrl = d.Icon,
                ShowInFilter = true, SortOrder = sort += 10, IsActive = true,
                CreatedAt = DateTimeOffset.UtcNow,
            });
            foreach (var ts in d.Tests)
                if (testBySlug.TryGetValue(ts, out var tid) && taggedTests.Add((tid, cid)))
                    db.Set<TestCategory>().Add(new TestCategory { TestId = tid, CategoryId = cid });
            foreach (var ps in d.Packages)
                if (pkgBySlug.TryGetValue(ps, out var pid))
                    db.Set<PackageCategory>().Add(new PackageCategory { PackageId = pid, CategoryId = cid });
        }

        // Keyword pass: lab names are standardised, so name keywords tag the
        // real catalogue reliably even when the explicit slug lists go stale.
        // Keep in sync with the concern chips in the app's All Tests screen.
        var keywordMap = new (string Slug, string[] Keys)[]
        {
            ("concern-diabetes", new[] { "sugar", "hba1c", "glucose", "insulin", "rbs" }),
            ("concern-anemia", new[] { "c.b.c", "iron", "ferritin", "esr", "reticulocyte", "peripheral" }),
            ("concern-heart-health", new[] { "lipid", "cholesterol", "hscrp", "apolipo", "homocyst", "troponin", "cpk" }),
            ("organ-heart", new[] { "lipid", "cholesterol", "hscrp", "apolipo", "homocyst", "troponin", "cpk" }),
            ("concern-vitamins", new[] { "vitamin", "b12", "d3", "folic" }),
            ("organ-kidney", new[] { "kidney", "rft", "creatinine", "urea", "uric", "urine" }),
            ("organ-liver", new[] { "liver", "lft", "sgpt", "sgot", "bilirubin", "ggt" }),
            ("organ-thyroid", new[] { "tsh", "t3", "t4", "thyro" }),
            ("persona-women", new[] { "hcg", "amh", "estradiol", "prolactin", "fsh", "torch", "pcod", "ca 125" }),
            ("persona-men", new[] { "testosterone", "psa", "semen" }),
            ("persona-elderly", new[] { "vitamin", "calcium", "uric", "lipid", "sugar", "creatinine", "tsh" }),
        };
        var allTests = await db.Set<Test>().AsNoTracking()
            .Select(t => new { t.Id, t.Name }).ToListAsync(ct);
        foreach (var (slug, keys) in keywordMap)
        {
            if (!cidBySlug.TryGetValue(slug, out var cid)) continue;
            foreach (var t in allTests)
            {
                var name = t.Name.ToLowerInvariant();
                if (keys.Any(k => name.Contains(k)) && taggedTests.Add((t.Id, cid)))
                    db.Set<TestCategory>().Add(new TestCategory { TestId = t.Id, CategoryId = cid });
            }
        }
        await db.SaveChangesAsync(ct);
    }

    // Link demo packages to their included tests so the package-detail screen's
    // "What's included" list is populated out of the box.
    private static async Task SeedPackageTestsAsync(AppDbContext db, CancellationToken ct)
    {
        if (await db.Set<PackageTest>().AnyAsync(ct)) return;

        var tests = await db.Set<Test>().AsNoTracking()
            .Select(t => new { t.Id, t.Slug }).ToListAsync(ct);
        var testBySlug = tests.ToDictionary(t => t.Slug, t => t.Id);
        var pkgs = await db.Set<Package>().AsNoTracking()
            .Select(p => new { p.Id, p.Slug }).ToListAsync(ct);

        // package slug → the test slugs it bundles (real catalogue).
        var map = new Dictionary<string, string[]>
        {
            ["women-profile"] = new[] { "c-b-c", "blood-sugar-f-pp", "iron-studies", "renal-profile-rft", "liver-profile-lft", "hba1c", "t3-t4-tsh", "vitamin-b12", "vitamin-d3", "ca-125" },
            ["men-profile"] = new[] { "c-b-c", "blood-sugar-f-pp", "liver-profile-lft", "renal-profile-rft", "vitamin-d3", "vitamin-b12", "testosterone-total", "urine-examination", "t3-t4-tsh", "iron-studies", "hba1c" },
            ["diabetes-profile"] = new[] { "c-b-c", "sr-creatinine", "blood-sugar-f-pp", "hba1c", "egfr" },
            ["cardiac-profile"] = new[] { "c-b-c", "hscrp", "renal-profile-rft", "liver-profile-lft", "hba1c", "vitamin-d3", "vitamin-b12" },
            ["arthritis-profile"] = new[] { "c-b-c", "e-s-r", "sr-uric-acid", "sr-calcium", "ra-factor", "crp", "anti-ccp", "ana-anti-nuclear-antibody", "vitamin-d3", "vitamin-b12" },
            ["mini-fever-profile"] = new[] { "c-b-c", "malarial-parasite-p-s", "sr-bilirubin-tdi", "urine-examination", "s-typhi-igm", "dengue-ns1" },
            ["maxi-fever-profile"] = new[] { "c-b-c", "malarial-antigen", "sr-bilirubin-tdi", "urine-examination", "dengue-igg-igm", "s-typhi-igm", "dengue-ns1", "sgpt" },
            ["men-cancer-marker"] = new[] { "afp", "cea", "psa", "c-b-c" },
            ["women-cancer-marker"] = new[] { "afp", "cea", "ca-125", "beta-hcg" },
            ["full-health-checkup"] = new[] { "c-b-c", "blood-sugar-f-pp", "liver-profile-lft", "renal-profile-rft", "vitamin-d3", "vitamin-b12", "hba1c", "t3-t4-tsh", "iron-studies", "urine-examination" },
        };
        foreach (var p in pkgs)
        {
            if (!map.TryGetValue(p.Slug, out var testSlugs)) continue;
            foreach (var ts in testSlugs)
                if (testBySlug.TryGetValue(ts, out var tid))
                    db.Set<PackageTest>().Add(new PackageTest
                    { Id = Guid.NewGuid(), PackageId = p.Id, TestId = tid });
        }
        await db.SaveChangesAsync(ct);
    }

    // Package-type filter categories (the master behind the home chips) + a demo
    // mapping onto the seeded packages so the filter works out of the box. Admins
    // manage both from the portal afterward.
    private static async Task SeedPackageCategoriesAsync(AppDbContext db, CancellationToken ct)
    {
        if (await db.Set<Category>().AnyAsync(c => c.Type == CatalogueCategoryType.Package, ct)) return;

        var cats = new (string Name, string Icon)[]
        {
            ("Full Body", "science"),
            ("Diabetes", "monitor_heart"),
            ("Heart", "favorite"),
            ("Women", "female"),
            ("Men", "male"),
            ("Fever", "thermostat"),
        };
        var bySlug = new Dictionary<string, Guid>();
        for (var i = 0; i < cats.Length; i++)
        {
            var id = Guid.NewGuid();
            var slug = Slugify(cats[i].Name);
            bySlug[slug] = id;
            db.Set<Category>().Add(new Category
            {
                Id = id, Name = cats[i].Name, Slug = slug, Type = CatalogueCategoryType.Package,
                IconUrl = cats[i].Icon, ShowInFilter = true, SortOrder = i * 10,
                IsActive = true, CreatedAt = DateTimeOffset.UtcNow,
            });
        }

        // Package slug → filter-category slugs it belongs to.
        var map = new Dictionary<string, string[]>
        {
            ["full-health-checkup"] = new[] { "full-body" },
            ["diabetes-profile"] = new[] { "diabetes" },
            ["cardiac-profile"] = new[] { "heart" },
            ["women-profile"] = new[] { "women", "full-body" },
            ["women-cancer-marker"] = new[] { "women" },
            ["men-profile"] = new[] { "men", "full-body" },
            ["men-cancer-marker"] = new[] { "men" },
            ["mini-fever-profile"] = new[] { "fever" },
            ["maxi-fever-profile"] = new[] { "fever" },
        };
        var pkgs = await db.Set<Package>().AsNoTracking()
            .Select(p => new { p.Id, p.Slug }).ToListAsync(ct);
        foreach (var p in pkgs)
        {
            if (!map.TryGetValue(p.Slug, out var catSlugs)) continue;
            foreach (var cs in catSlugs)
                if (bySlug.TryGetValue(cs, out var cid))
                    db.Set<PackageCategory>().Add(new PackageCategory { PackageId = p.Id, CategoryId = cid });
        }
        await db.SaveChangesAsync(ct);
    }

    private static string Slugify(string name)
    {
        var lowered = name.Trim().ToLowerInvariant();
        var chars = lowered.Select(c => char.IsLetterOrDigit(c) ? c : '-').ToArray();
        var slug = new string(chars).Trim('-');
        while (slug.Contains("--")) slug = slug.Replace("--", "-");
        return slug.Length == 0 ? Guid.NewGuid().ToString("N")[..8] : slug;
    }

    // ── D2 home feed + nav + rebrand (version-keyed) ─────────────────────────
    // home_sections and nav_items are pure content tables (no FKs), so a version
    // bump replaces them wholesale on existing DBs too. Bump ContentSeedVersion
    // whenever the default layout changes. All merchandising numbers below are
    // backed by seeded catalogue prices — never invented.
    private const string ContentSeedVersionKey = "content_seed_version";
    private const int ContentSeedVersion = 14;

    private static async Task SeedVersionedContentAsync(AppDbContext db, CancellationToken ct)
    {
        var versionRow = await db.AppConfigs.FirstOrDefaultAsync(c => c.Key == ContentSeedVersionKey, ct);
        if (int.TryParse(versionRow?.Value, out var current) && current >= ContentSeedVersion) return;

        db.Set<HomeSection>().RemoveRange(await db.Set<HomeSection>().ToListAsync(ct));
        db.Set<NavItem>().RemoveRange(await db.Set<NavItem>().ToListAsync(ct));

        // Sort in steps of 10 so admins can insert between rows. LifestyleRail
        // ships hidden to keep the default visible feed at 12 (premium ≠ busy).
        var layout = new (int Sort, HomeSectionType Type, string Title, bool Visible, string? Config)[]
        {
            (10, HomeSectionType.CategoryGrid, "", true,
             """{"tiles":[{"label":"Blood Tests","icon":"bloodtype","deepLink":"/blood-tests","offerText":"Up to 50% off","bg":"#CDEAEA","imageUrl":"https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=600&q=80&auto=format&fit=crop"},{"label":"X-Rays, Scans and MRI","icon":"radar","deepLink":"/services/mri","offerText":null,"bg":"#D6DDF4","imageUrl":"https://images.unsplash.com/photo-1516069677018-378515003435?w=600&q=80&auto=format&fit=crop"},{"label":"Doctor & Diet Consults","icon":"medical_services","deepLink":"/services/doctor","offerText":null,"bg":"#F8DCD4","imageUrl":"https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=600&q=80&auto=format&fit=crop"}]}"""),
            (30, HomeSectionType.PrescriptionUpload, "", true,
             """{"cards":[{"title":"Book Via Doctor Prescription","subtitle":"Tests booked as per your prescription","badge":"New","deepLink":"/prescription","bg":"#3159A9","dark":true,"icon":"description"},{"title":"Book Lab Tests @ Home","subtitle":"Doorstep sample service","deepLink":"/blood-tests","bg":"#CDEAEA","dark":false,"icon":"home"}]}"""),
            (40, HomeSectionType.FeaturedPackages, "Popular Blood Test Packages", true,
             """{"chips":["Popular","Full Body","Diabetes","Heart","Women"],"chipQueries":{"Full Body":"full-body","Diabetes":"diabetes","Heart":"heart","Women":"women"},"offerStrip":{"text":"Save up to 76% on all health packages."}}"""),
            (50, HomeSectionType.Banner, "", true, null),
            (60, HomeSectionType.CustomPackageBanner, "Build your own package", true,
             """{"subtitle":"Pick only the tests you need","cta":"Start Building","deepLink":"/packages/custom/builder"}"""),
            (70, HomeSectionType.PersonaPlans, "Care for everyone", true,
             """{"items":[{"label":"Women's Care","icon":"female","deepLink":"/category/persona-women","bg":"#F8DCD4","imageUrl":"https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&q=80&auto=format&fit=crop"},{"label":"Men's Care","icon":"male","deepLink":"/category/persona-men","bg":"#D6DDF4","imageUrl":"https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80&auto=format&fit=crop"},{"label":"Elderly Care","icon":"elderly","deepLink":"/category/persona-elderly","bg":"#CDEAEA","imageUrl":"https://images.unsplash.com/photo-1447452001602-7090c7ab2db3?w=600&q=80&auto=format&fit=crop"}]}"""),
            (80, HomeSectionType.OrganRail, "Checkups by organ", true,
             // Organ artwork: Servier Medical Art (smart.servier.com) via
             // Wikimedia Commons — CC-BY 4.0, attribution required in a
             // production release (or replace with commissioned artwork).
             """{"items":[{"label":"Heart","icon":"favorite","deepLink":"/category/organ-heart","fromPricePaise":34900,"bg":"#FFD9C8","bg2":"#FF9E8C","fit":"contain","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Cardiovascular_system_-_Heart_5_--_Smart-Servier.png/500px-Cardiovascular_system_-_Heart_5_--_Smart-Servier.png"},{"label":"Liver","icon":"science","deepLink":"/category/organ-liver","fromPricePaise":39900,"bg":"#FFE7AE","bg2":"#FFB75E","fit":"contain","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Digestive_system_-_Liver_2_--_Smart-Servier.png/500px-Digestive_system_-_Liver_2_--_Smart-Servier.png"},{"label":"Kidney","icon":"water_drop","deepLink":"/category/organ-kidney","fromPricePaise":34900,"bg":"#DAE0FF","bg2":"#9FAEF2","fit":"contain","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/5/5a/Urinary_system_-_Kidney_4_--_Smart-Servier.png"},{"label":"Thyroid","icon":"health_and_safety","deepLink":"/category/organ-thyroid","fromPricePaise":34900,"bg":"#C6F2ED","bg2":"#6FCFC6","fit":"contain","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Glands_-_Normal_thyroid_--_Smart-Servier.png/500px-Glands_-_Normal_thyroid_--_Smart-Servier.png"}]}"""),
            (90, HomeSectionType.ConcernRail, "Shop by health concern", true,
             """{"items":[{"label":"Diabetes","icon":"monitor_heart","deepLink":"/category/concern-diabetes","bg":"#CDEAEA","imageUrl":"https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80&auto=format&fit=crop"},{"label":"Anemia","icon":"bloodtype","deepLink":"/category/concern-anemia","bg":"#F8DCD4","imageUrl":"https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80&auto=format&fit=crop"},{"label":"Heart Health","icon":"favorite","deepLink":"/category/concern-heart-health","bg":"#FDEBC8","imageUrl":"https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=600&q=80&auto=format&fit=crop"},{"label":"Vitamins","icon":"wb_sunny","deepLink":"/category/concern-vitamins","bg":"#D6DDF4","imageUrl":"https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&q=80&auto=format&fit=crop"}]}"""),
            (100, HomeSectionType.LifestyleRail, "Lifestyle checks", false,
             """{"items":[{"label":"Fatigue","icon":"battery_alert","deepLink":"/category/concern-vitamins"},{"label":"Stress","icon":"self_improvement","deepLink":"/category/organ-thyroid"},{"label":"Immunity","icon":"shield","deepLink":"/category/concern-heart-health"}]}"""),
            (110, HomeSectionType.TrustBlock, "Why book with us", true,
             """{"journey":[{"icon":"event_available","label":"Book online"},{"icon":"home","label":"Home sample pickup"},{"icon":"science","label":"Lab processing"},{"icon":"description","label":"Reports in-app"}]}"""),
            (120, HomeSectionType.ReferEarn, "Refer & earn", true,
             """{"headline":"Invite friends & family","subtitle":"They get tested, you get rewarded","cta":"Copy your code"}"""),
            (130, HomeSectionType.Articles, "Health reads", true, null),
        };
        foreach (var (sort, type, title, visible, config) in layout)
        {
            db.Set<HomeSection>().Add(new HomeSection
            {
                Id = Guid.NewGuid(), SectionType = type, Title = title, ConfigJson = config,
                SortOrder = sort, IsVisible = visible, UpdatedAt = DateTimeOffset.UtcNow,
            });
        }

        // Bottom nav: 4 tabs (D2 reshape). '/health' keeps its route; only the
        // label becomes "Vitals". Reports folds into Profile + Care entry points.
        var nav = new (string Label, string Icon, string Route)[]
        {
            ("Home", "home", "/home"),
            ("Care", "favorite", "/care"),
            ("Vitals", "monitor_heart", "/health"),
            ("Profile", "person", "/profile"),
        };
        for (var i = 0; i < nav.Length; i++)
        {
            db.Set<NavItem>().Add(new NavItem
            {
                Id = Guid.NewGuid(), Label = nav[i].Label, IconUrl = nav[i].Icon,
                Route = nav[i].Route, SortOrder = i, IsVisible = true,
            });
        }

        // Rebrand from the company logo (navy-led, user-approved): these UPDATE
        // existing rows, so they ride the version bump rather than SeedConfigAsync
        // (which only inserts missing keys).
        var rebrand = new Dictionary<string, string>
        {
            // v3: action theme matching the light-blue reference color.
            // secondary green feeds the offer-strip gradient end.
            ["primary_color"] = "#428AC7",
            ["nav_accent_color"] = "#428AC7",
            ["secondary_color"] = "#36B665",
            ["app_tagline"] = "Your health, our priority",
        };
        foreach (var cfg in await db.AppConfigs.Where(c => rebrand.Keys.Contains(c.Key)).ToListAsync(ct))
            cfg.Value = rebrand[cfg.Key];

        if (versionRow is null)
            db.AppConfigs.Add(new AppConfig
            {
                Id = Guid.NewGuid(), Key = ContentSeedVersionKey, Value = ContentSeedVersion.ToString(),
                ValueType = "int", Category = "seed", IsPublic = false,
            });
        else
            versionRow.Value = ContentSeedVersion.ToString();
        await db.SaveChangesAsync(ct);
    }

    // Generic, brand-neutral editorial content for the articles rail (D2).
    private static async Task SeedArticlesAsync(AppDbContext db, CancellationToken ct)
    {
        if (await db.Set<Article>().AnyAsync(ct)) return;

        var articles = new (string Title, string Excerpt, string Body, string Category, bool Featured)[]
        {
            ("Why an annual full-body checkup matters",
             "Preventive testing catches silent conditions years before symptoms show.",
             "<p>Most lifestyle conditions — diabetes, thyroid imbalance, high cholesterol — develop silently. An annual panel establishes your baseline and flags drift early, when small changes still work.</p>",
             "Prevention", true),
            ("Understanding your vitamin D report",
             "What the 25-OH number means and when to act on it.",
             "<p>Vitamin D below 20 ng/mL is generally considered deficient and 20–29 insufficient. Levels respond well to supervised supplementation and sunlight — retest after 8–12 weeks.</p>",
             "Reports", false),
            ("Fasting before a blood test: the rules",
             "Which tests need fasting, for how long, and what breaks a fast.",
             "<p>Lipid profiles and fasting glucose typically need 8–12 hours without food. Water is fine; tea, coffee and gum are not. When in doubt, check the test's fasting note before your slot.</p>",
             "Guides", false),
            ("HbA1c vs fasting sugar: what's the difference?",
             "One is a snapshot, the other a three-month average.",
             "<p>Fasting glucose reflects a single morning; HbA1c averages roughly 90 days of blood sugar. Doctors read them together to separate a stressful week from a real trend.</p>",
             "Diabetes", false),
        };
        foreach (var (title, excerpt, body, category, featured) in articles)
        {
            db.Set<Article>().Add(new Article
            {
                Id = Guid.NewGuid(), Title = title, Slug = Slugify(title),
                Excerpt = excerpt, Body = body, Category = category, Language = "en",
                IsFeatured = featured, IsPublished = true,
                CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
            });
        }
        await db.SaveChangesAsync(ct);
    }

    // Idempotent demo accounts so each front-end can authenticate end-to-end.
    private static async Task SeedDemoUsersAsync(AppDbContext db, IHashService hasher, CancellationToken ct)
    {
        var roleId = await db.Roles.Where(r => true).ToDictionaryAsync(r => r.Name, r => r.Id, ct);

        // 1) super_admin (admin portal) — password now, TOTP enrolled on first login.
        if (!await db.Users.AnyAsync(u => u.IsAdminPortalUser, ct))
        {
            var admin = new User
            {
                Id = Guid.NewGuid(),
                Name = "Platform Admin",
                Mobile = "+919900000001",
                Email = DefaultAdminEmail,
                IsAdminPortalUser = true,
                PasswordHash = hasher.Hash(DefaultAdminPassword),
                PasswordChangedAt = DateTimeOffset.UtcNow,
                ReferralCode = "B2SADMIN",
                PiiEncrypted = false,
            };
            db.Users.Add(admin);
            AssignRole(db, admin.Id, roleId, "super_admin");
        }

        // 2) technician (Flutter technician app) — User carries the role, Technician the login.
        if (!await db.Technicians.AnyAsync(t => t.EmployeeId == DefaultTechEmployeeId, ct))
        {
            var techUser = new User
            {
                Id = Guid.NewGuid(),
                Name = "Demo Technician",
                Mobile = "+919900000002",
                ReferralCode = "B2STECH1",
                PiiEncrypted = false,
            };
            db.Users.Add(techUser);
            AssignRole(db, techUser.Id, roleId, "technician");
            db.Technicians.Add(new Technician
            {
                Id = Guid.NewGuid(),
                UserId = techUser.Id,
                EmployeeId = DefaultTechEmployeeId,
                PasswordHash = hasher.Hash(DefaultTechPassword),
                Name = "Demo Technician",
                Mobile = "+919900000002",
                Status = TechnicianStatus.Offline,
                IsActive = true,
            });
        }

        // 3) partner (Flutter partner app) — logs in via OTP on this mobile.
        if (!await db.Set<Partner>().AnyAsync(p => p.Mobile == DefaultPartnerMobile, ct))
        {
            var partnerUser = new User
            {
                Id = Guid.NewGuid(),
                Name = "Demo Partner",
                Mobile = DefaultPartnerMobile,
                ReferralCode = "B2SPART1",
                PiiEncrypted = false,
            };
            db.Users.Add(partnerUser);
            AssignRole(db, partnerUser.Id, roleId, "partner");
            db.Set<Partner>().Add(new Partner
            {
                Id = Guid.NewGuid(),
                UserId = partnerUser.Id,
                Name = "Demo Partner",
                Mobile = DefaultPartnerMobile,
                Type = PartnerType.Individual,
                Status = PartnerStatus.Verified,
                VerifiedAt = DateTimeOffset.UtcNow,
                CommissionPercent = 10m,
            });
        }

        await db.SaveChangesAsync(ct);
    }

    private static void AssignRole(AppDbContext db, Guid userId,
        IReadOnlyDictionary<string, Guid> roleId, string role)
    {
        if (roleId.TryGetValue(role, out var rid))
            db.Set<UserRole>().Add(new UserRole
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                RoleId = rid,
                AssignedAt = DateTimeOffset.UtcNow,
            });
    }

    private static async Task SeedPermissionsAsync(AppDbContext db, CancellationToken ct)
    {
        var existing = await db.Permissions.Select(p => p.Code).ToListAsync(ct);
        foreach (var code in PermissionCodes.Where(c => !existing.Contains(c)))
        {
            var parts = code.Split('.', 2);
            db.Permissions.Add(new Permission
            {
                Id = Guid.NewGuid(),
                Code = code,
                Module = parts[0],
                Action = MapAction(parts.Length > 1 ? parts[1] : "view"),
                Description = code,
            });
        }
        await db.SaveChangesAsync(ct);
    }

    private static async Task SeedRolesAsync(AppDbContext db, CancellationToken ct)
    {
        var allPermissions = await db.Permissions.ToListAsync(ct);
        var byCode = allPermissions.ToDictionary(p => p.Code, p => p.Id);

        // System roles.
        await EnsureRoleAsync(db, "super_admin", "Full access", isSystem: true,
            allPermissions.Select(p => p.Code), byCode, ct);

        var adminCodes = allPermissions.Select(p => p.Code)
            .Where(c => c is not ("roles.delete" or "users.delete"));
        await EnsureRoleAsync(db, "admin", "All except destructive ops", isSystem: true,
            adminCodes, byCode, ct);

        // Non-system roles.
        foreach (var (role, codes) in RolePermissionMap)
            await EnsureRoleAsync(db, role, role, isSystem: false, codes, byCode, ct);
    }

    private static async Task EnsureRoleAsync(AppDbContext db, string name, string description,
        bool isSystem, IEnumerable<string> codes, IReadOnlyDictionary<string, Guid> byCode,
        CancellationToken ct)
    {
        var role = await db.Roles.FirstOrDefaultAsync(r => r.Name == name, ct);
        if (role is null)
        {
            role = new Role { Id = Guid.NewGuid(), Name = name, Description = description, IsSystem = isSystem };
            db.Roles.Add(role);
            await db.SaveChangesAsync(ct);
        }

        var assigned = await db.RolePermissions.Where(rp => rp.RoleId == role.Id)
            .Select(rp => rp.PermissionId).ToListAsync(ct);
        foreach (var code in codes)
        {
            if (!byCode.TryGetValue(code, out var pid) || assigned.Contains(pid)) continue;
            db.RolePermissions.Add(new RolePermission { Id = Guid.NewGuid(), RoleId = role.Id, PermissionId = pid });
        }
        await db.SaveChangesAsync(ct);
    }

    private static async Task SeedConfigAsync(AppDbContext db, CancellationToken ct)
    {
        var existing = await db.AppConfigs.Select(c => c.Key).ToListAsync(ct);
        foreach (var (key, value) in SecurityConfig.Where(c => !existing.Contains(c.Key)))
        {
            db.AppConfigs.Add(new AppConfig
            {
                Id = Guid.NewGuid(),
                Key = key,
                Value = value,
                ValueType = "string",
                Category = "security",
                IsPublic = false,
            });
        }

        // Public white-label branding (served by /config/branding, zero hardcoding).
        // Colors come from the company logo: navy #203078 (wordmark) leads, cyan
        // #2898D8 (feather) is a sparing secondary accent.
        // trust_* keys ship EMPTY: the operator fills real accreditations/counters;
        // the app hides trust furniture while they're empty (no invented numbers).
        var branding = new (string Key, string Value)[]
        {
            ("app_name", "Unique Diagnostic Centre"),
            ("app_tagline", "Your health, our priority"),
            ("primary_color", "#203078"),
            ("secondary_color", "#2898D8"),
            ("nav_accent_color", "#428AC7"),
            ("support_phone", "1800-891-1234"),
            ("trust_accreditations", ""),
            ("trust_stat_reports", ""),
            ("trust_stat_customers", ""),
            ("trust_stat_labs", ""),
        };
        foreach (var (key, value) in branding.Where(c => !existing.Contains(c.Key)))
        {
            db.AppConfigs.Add(new AppConfig
            {
                Id = Guid.NewGuid(),
                Key = key,
                Value = value,
                ValueType = "string",
                Category = "branding",
                IsPublic = true,
            });
        }

        // Booking lifecycle knobs (P0c). Non-public; read via GetIntConfigAsync
        // with the same fallbacks, so these are documentation as much as data.
        var bookingCfg = new (string Key, string Value)[]
        {
            ("booking_reschedule_max", "2"),
            ("booking_reschedule_window_hours", "4"),
        };
        foreach (var (key, value) in bookingCfg.Where(c => !existing.Contains(c.Key)))
        {
            db.AppConfigs.Add(new AppConfig
            {
                Id = Guid.NewGuid(),
                Key = key,
                Value = value,
                ValueType = "int",
                Category = "booking",
                IsPublic = false,
            });
        }
    }

    // The action CHECK constraint allows a fixed verb set; map richer codes onto it.
    private static PermissionAction MapAction(string action) => action switch
    {
        "view" or "view_pii" or "view_ai_summary" => PermissionAction.View,
        "create" or "upload" => PermissionAction.Create,
        "update" or "deactivate" or "reschedule" or "cancel" or "adjust"
            or "activate" or "respond" or "close" or "manage_zones" => PermissionAction.Update,
        "delete" => PermissionAction.Delete,
        "export" or "download" => PermissionAction.Export,
        "approve" or "process" or "verify" or "payout" => PermissionAction.Approve,
        "assign" or "assign_technician" => PermissionAction.Assign,
        "manage" => PermissionAction.Manage,
        "broadcast" => PermissionAction.Broadcast,
        "refund" => PermissionAction.Approve,
        _ => PermissionAction.View,
    };
}
