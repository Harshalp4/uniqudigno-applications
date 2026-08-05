# Unique Diagnostic Centre (Bit2sky / VitalScan) — Development Restart Master Prompt

**Version:** 2.0 · **Date:** 15 July 2026
**What changed in v2:** Added a full **UI/UX design-parity track** built from 20 real Healthians app screenshots (splash, home, care, vitals, profile, catalogue, HealthKarma, family tracker). The goal is Healthians-level richness with a **premium, more restrained execution**, driven entirely by our white-label brand tokens.

**How to use:** Copy the prompt in the box below into a fresh Claude / Cowork session with the `Healthians app` folder connected. **Also attach the Healthians reference screenshots to that session** — the prompt describes them in detail, but the agent will do better design work seeing them. Keep this file in the project root so the agent can read the reference sections below the prompt.

---

## THE PROMPT (copy-paste from here)

```
You are the lead engineer AND product designer on "Unique Diagnostic Centre" — a
white-label, at-home diagnostics platform (browse lab tests/packages → cart → book
home sample collection → reports in-app). The project folder is connected.

THREE NAMES, ONE PRODUCT: codebase namespace = Bit2sky, product placeholder =
VitalScan, current brand = Unique Diagnostic Centre. "Healthians" is the real
third-party company we benchmark against — we are building on the same theme,
NOT copying their brand.

REPO LAYOUT
- backend/            .NET 10 Web API, Clean/Onion. PostgreSQL (EF Core 9,
                      schemas: core, content, catalogue, booking, commerce, comms,
                      reports, admin), Redis, RS256 JWT, Razorpay, SignalR hubs,
                      multi-channel notifications (WhatsApp→SMS, FCM, email, in-app).
                      Envelope { success, message, data, errors, pagination,
                      correlationId }; customer calls require header X-App-Source.
- mobile/bit2sky_customer/     Flutter customer app (Riverpod, go_router, dio,
                               Hive + secure storage, fl_chart, biometrics).
- mobile/vitalscan_technician/ + mobile/vitalscan_partner/  Flutter, early stage.
- web/vitalscan-admin/         Angular admin portal, early stage (admin API done).
- wireframes/mobile-ui-healthians-inspired.html  — the chosen visual direction.

BEFORE ANY CODE, read these in the project root as the source of truth:
1. DEVELOPMENT_RESTART_PROMPT.md — THIS file; §"DESIGN REFERENCE" below the prompt
   is the screen-by-screen spec extracted from real Healthians screenshots.
2. DESIGN_TECHNICAL.md — architecture, data model, API surface, gap analysis
3. COMPARISON_LAYMAN.md — plain-English status vs Healthians
4. VitalScan_QA_Report.md + FIXES_APPLIED.md — QA findings (fixed) + pending manual steps
5. BROKEN_FLOWS.md — nav bugs; Flutter patches (root cause #2) may still be pending
6. mobile/bit2sky_customer/lib/core/theme/ — existing token system (teal700 #00897B
   primary, status colors, neutrals) and models/branding_config.dart (DB-driven brand)

DESIGN NORTH STAR (this is now a first-class work track, equal to features)
The user has provided real Healthians app screenshots. Target: their level of
content richness and merchandising, executed MORE premium and professional —
more white space, fewer competing gradients, consistent card language, no visual
noise. HARD RULES:
- Every color, logo, name, and support phone comes from brand tokens
  (/config/branding + AppColors). NEVER hardcode Healthians branding, imagery,
  or copy. Primary = branding primary_color (currently #00897B teal); derive a
  50/100/700/800 tonal ramp from it at runtime or via seeded tokens.
- One accent system: amber/orange ONLY for offers/wallet/rewards; status colors
  only for health status. Everything else stays in the primary ramp + neutrals.
- Typography scale, radius scale (12/16/20), spacing scale (4pt), and elevation
  (soft, single-source shadows) must be uniform across every screen.
- All merchandising content (banners, sections, chips, section order) is DB-driven
  via content.home_sections / quick_actions — the design system renders whatever
  the DB sends; hide empty sections; never fabricate data.
- Premium ≠ busy: cap the home feed at ~10 section types per screen, one CTA
  style per card, illustrations consistent in style (no mixed 3D/flat/photo soup).

DESIGN-PARITY WORK PACKAGES (D-track — see §DESIGN REFERENCE for full specs)
D1. Design-system refresh: tonal ramp from brand color, elevated card spec,
    section-header spec ("Title + See All >"), chip/filter spec, price row spec
    (₹final bold + ₹mrp strikethrough + % off badge), offer-strip component,
    trust-badge row, persistent Call-to-Book FAB (branding.supportPhone),
    bottom nav = 5 tabs: Avatar/New · Home · Care · Vitals · Profile.
D2. Home rebuild (renderer-driven): personalized header (Hi {name}, location
    selector, wallet chip ₹balance, notification bell + unread badge, cart),
    rotating search placeholder + voice input, category tiles w/ "Up to X% off"
    chips (Blood Tests / Scans / Consultations), banner carousel, popular
    packages w/ filter chips + package cards (test count, offer badge, price
    row, BOOK NOW), Make-Your-Own-Package banner (custom builder exists),
    persona care plans (Women/Men/Elderly), tests-by-organ rail, health
    concerns rail, lifestyle concerns rail, last-viewed tests (local history),
    trust section (accreditations, "why X customers trust us"), refer & earn
    banner, articles rail (title, summary, read-time, language from DB),
    checkup-journey explainer, feedback banner. ALL sections DB-ordered.
D3. Care tab: doctor-prescription upload booking (new flow — upload Rx, ops
    books for you), lifestyle-based test entries, HealthKarma-style health-score
    screen (gauge + risk buckets High/Medium/Low + peer percentile + suggested
    tests from score), doctor/dietician consult cards, supplements section only
    if catalogue supports it (else omit — no dead UI).
D4. Vitals tab: diet plan card (kcal, ideal weight, BMI), track-your-diet
    (kcal eaten vs goal), health trackers (steps, sugar, BP, weight) wired to
    existing /health endpoints, report-driven "needs improvement" parameter
    chips (e.g. B12/LDL/Vit-D with values), suggested nutrition/lifestyle cards,
    quick-help (call + chat→Wellio).
D5. Profile: wallet balance strip, corporate verification, My Wallet, Bookings,
    Reports, Appointments, Family (with per-member health score + add-member
    incentive badge if a wallet promo exists in DB), Addresses, WhatsApp channel
    join, Refer & Earn, Help, Privacy, Logout, app version.
D6. Catalogue screens: location/pincode selector at top, browse-by-concern
    chips, packages-by-gender&age grid, popular tests list with inline "+" add,
    advisor call banner. Package/test detail: tests-included, fasting/report-time/
    recommended-for meta rows, price row, sticky Add to Cart.

FUNCTIONAL ROADMAP (unchanged from v1 — run in parallel with D-track)
P0 Revenue: (a) activate Razorpay checkout UI (order already created server-side;
   wire payment sheet + HMAC verify + wallet-points combo), (b) pay-on-collection
   COD end-to-end, (c) reschedule endpoint + UI (RescheduleCount + atomic slot
   re-reserve), (d) order-tracking screen on the status lifecycle via
   BookingTrackingHub.
P1 Surface what's built: notifications screen + badge, articles screen,
   subscriptions UI, referral earn/redeem, pincode serviceability check.
P2 True gaps: radiology/scans catalogue + centre picker + booking, diet-plan
   generation flow, doctor-consult scheduling, live technician tracking (map+ETA).
P3 Differentiators: ABDM/ABHA linking + FHIR reports, WhatsApp report delivery,
   express-collection ETA tier, health-score streaks + chronic re-test reminders,
   DPDP consent screens. Then technician app → partner app → admin portal.

FIRST SESSION CHECKLIST (before anything else)
1. Verify BROKEN_FLOWS.md root-cause-#2 Flutter patches were applied in
   home_section_renderer.dart / home_screen.dart; apply if not.
2. Verify one-time DB updates ran (quick_actions deep links; app_name).
3. Build gates green: dotnet build + dotnet test (backend), flutter analyze
   (customer app), smoke_test.sh (API :5001, Development, Auth__EchoEmailOtp=true,
   docker bit2sky-pg + redis).

NON-NEGOTIABLE WORKING RULES
- Never fabricate UI data; every section renders from API/DB and hides when empty.
- Brand/white-label: zero hardcoded names, colors, prices, coupons, phones.
- Keep envelope + X-App-Source contract; DTOs on the wire; IDOR ownership checks;
  atomic slot mutations (conditional ExecuteUpdateAsync).
- New home sections = new SectionType handled by the renderer + DB seed, not
  hardcoded widgets.
- After each work package: build gates + smoke test + update DESIGN_TECHNICAL.md
  status tables. If a doc contradicts code, trust code and fix the doc.

Start with the FIRST SESSION CHECKLIST, report findings, then propose whether to
begin with D1+D2 (design uplift) or P0a (payments) and wait for my confirmation.
```

---

## DESIGN REFERENCE — extracted from 20 real Healthians app screenshots (July 2026)

This section is the detailed spec the prompt points to. It records what the reference app actually does, screen by screen, plus how we adapt it premium + white-label. **Adapt patterns, never copy Healthians branding, mascots, photos, or copy.**

### R1. Global patterns

- **Persistent "Call to Book" FAB** — pill with phone icon, bottom-right on every browse screen. Ours exists; keep it wired to `branding.supportPhone`.
- **Bottom nav (5):** Avatar (with "New" ribbon when something new for the user) · Home · Care · Vitals · Profile. Active tab gets a soft pill highlight. → We currently have Home/Care/Reports/Health/Profile; rename/reshape to Home · Care · Vitals · Profile + avatar slot, and fold Reports under Profile + Care entry points.
- **Search bar everywhere** — rotating placeholder cycling real test names ("Search for 'CBC' / 'KFT' / 'LFT' / 'MRI Brain' / 'Full body checkup'") + mic icon (voice search). Rotation list should come from popular tests API.
- **Price row convention:** `₹1143  ₹4971(strikethrough)  UPTO 84% OFF (badge)` — discount always framed as savings; group-offer badge variant exists.
- **Section header convention:** bold title left, "See All >" right.
- **Trust furniture:** accreditation badges (CAP & NABL), "Why 8.5M Indians trust…", on-time collection stat, checkup-journey explainer. → Ours: DB-driven trust section (accreditations + counters from config), no invented numbers.
- **Tone:** friendly, bilingual (Hindi/Hinglish appears in articles + feedback banner). → Ours: keep copy professional English first; article language comes from content DB (multi-language field exists in our content model? if not, add `language` to articles).

### R2. Splash
Full-bleed brand color, white logo + tagline centered upper-third, lifestyle photo fading in lower half. → Ours already shows logo card on teal; acceptable — optionally add DB-driven splash image slot.

### R3. Home (logged-in)
Order observed: (1) personalized header — "Hi, Harshal", location "mumbai >", occasion graphic (Doctor's Day), wallet chip ₹1175, bell with unread badge (9), cart; (2) search; (3) three category tiles with discount chips — Blood Tests "Up to 79% off", X-Rays/Scans/MRI "70%", Doctor & Diet Consultations "75%"; (4) two mid cards — "Book Via Doctor Prescription (New)" + "Book Lab Tests @ Home"; (5) Popular Blood Test Packages with filter chips (Popular/Vitamins/Allergy/Thyroid/…) + green offer strip ("Get upto 70% OFF on all bookings") + package cards (name, N tests, Details >>, GROUP OFFERS badge, EXCLUSIVE OFFER price row, BOOK NOW footer); (6) banner carousel (dot indicators) — themed campaigns (food-intolerance, PCOD awareness); (7) Make Your Own Package — "Choose only the tests you need. Save up to 65%. Start Now" (→ our custom_package_builder); (8) Care Plans That Match You — persona cards Women/Men/Elderly; (9) Book Tests by Organ — organ cards with price-from + Book Now (Bone ₹504, Stomach ₹808, Kidney ₹831…); (10) quiz banner ("Brain Health & Memory Check — Start Test"); (11) Food Intolerance section; (12) seasonal section ("Summer Health Alert" male/female packages); (13) Radiology Tests rail — Digital X-ray from ₹248, Ultrasound ₹327, CT…; (14) Health Concerns rail (Fever, STD, Diabetes photo cards + Book Now); (15) Lifestyle Concerns rail (Vitamins, Alcoholism, Poor diet); (16) Allergy Tests rail (Veg&Non-veg, Drugs, Pets); (17) Last Viewed Tests (recently-viewed w/ Add); (18) Express Booking banner ("Just select a slot & add tests at home"); (19) Health Insights ("check how healthy people are around you" — peer stats); (20) trust block; (21) Refer & Earn Rewards banner (monthly prizes); (22) CGHS/Govt panels card; (23) Health Checkup Journey explainer; (24) Quick & Easy Report Access ("reports within 6 hours via WhatsApp, SMS, Email"); (25) feedback banner; (26) Articles for you (image, Hindi title, summary, "29 min(s) read") + Read more.

**Our adaptation:** all of these become `SectionType`s in `home_section_renderer.dart` fed by `content.home_sections` rows (type, title, payload, sort). Ship seeds for: category_tiles, prescription_upload, package_carousel_with_chips, offer_strip, banner_carousel, custom_package_banner, persona_plans, organ_rail, concern_rail, lifestyle_rail, seasonal_rail, radiology_rail, last_viewed (client-side), express_booking_banner, trust_block, refer_earn_banner, journey_explainer, report_access_banner, feedback_banner, articles_rail. Cap default seed to ~12 sections for a calmer premium feed; admins can add more.

### R4. Care tab
"Book Via Doctor Prescription" hero (upload Rx → experts book for you — NEW FLOW for us: needs upload endpoint + ops queue in admin); Lifestyle Based Tests icon grid (Alcoholism, Eating Poorly, Junk Food, Medicine Overuse, Anger, Heartburn, Low Iron Diet, Poor Nutrition); HealthKarma entry banner; doctor/dietician consult upsell ("from ₹129", cashback note); CGHS panels; Health Supplements e-commerce (their HerbVed) — **omit unless we add a supplements catalogue**; "Your Doctor" / "Your Dietician" cards.

### R5. Health score screen ("HealthKarma" pattern)
Circular gauge (71%) with red→green sweep; "Your Probable Risks" bucketed High/Medium/Low with counts; expandable risk rows (e.g. Vitamin B12 Deficiency); peer comparison line ("31% peers are healthier than you"); "Suggested tests based on your score" → package card with tests-included, meta rows (No fasting / Report in 24h / Recommended for everyone), price row, Add to Cart. → We have score + history + breakdown APIs; add risk-bucket + suggested-test mapping (recommendation service exists) and the peer percentile (needs aggregate endpoint — compute from anonymized score distribution).

### R6. Vitals tab
Diet Plan summary card (Daily kcal, Ideal weight, Current weight, BMI + Normal tag, Edit, Veg/Non-veg toggle); "Track Your Diet" kcal-eaten vs goal; "Generated Diet Plans" list (→ our DietPlan entity); Health Trackers list — Steps, Log Sugar, Blood Pressure, Track Weight (+ quick-add each); "Your Vitals" cards (BP 113/68, Weight 72kg); report-driven improvement chips (Vitamin-B12 101 pg/ml, LDL 107, Vit-D 29 — values from latest report parameters); Suggested Nutrition / Lifestyle cards; Quick Help (Call now / Chat with us → Wellio).

### R7. Profile
Header (name, email, avatar, Edit); wallet balance strip with info tooltip; Corporate Verification row; Your Information group — My Wallet (promo/wallet/flyer cash split), Bookings, Reports, Appointments, Family (incentive badge "Get ₹500 on every new member" — only if a live promo exists in DB), Addresses, Supplements (omit for us), Join-on-WhatsApp row, third-party loyalty row (their IndiGo BluChip — skip); Others — Refer and Earn, Help, Privacy Policy; Logout button; version footer.

### R8. Family / Health Tracker screen
Member cards: avatar, name, age, relationship, gender, per-member Health Score X/100, Edit; add-member incentive strip; "+Add New Member" CTA. → We have family CRUD + booking-per-member; add per-member health score (exists via reports per patient) to family_screen.

### R9. Catalogue ("Blood Tests") screen
Back + title + cart; location selector; search; Browse by Health Concern icon rail (Vitamins, Allergy, Thyroid, Kidney…); advisor call banner ("Talk to our health advisors for discounts — Call Now"); Full-body Checkup Packages (offer strip + package cards); Popular Blood Tests list — name in brand color, price row, inline ⊕ add, View More; Packages by Gender & Age — two rows of age-band avatar tiles (male row / female row: up-to-12, 12-18, 18-40, 40-60, 60+); prescription-upload banner repeats.

### R10. Design-language notes (what "premium" means for us)
- Reference uses MANY competing gradients, 3D mascots, photos, and emoji avatars together. We standardize: one illustration style, gradients only on hero/offer surfaces, photography only in editorial (articles/banners).
- Cards: white, radius 16-20, 1px hairline `borderDefault` OR soft shadow — never both stacked; consistent 16px internal padding.
- Color: primary ramp from branding (#00897B today) for nav/CTAs/links; amber #FB8C00 family strictly for money (offers, wallet, rewards, incentives); status green/red only for health values. This is already the documented intent in AppColors — enforce it in the new components.
- Dark-on-light neutrals from existing palette; text hierarchy textPrimary/textSecondary only (no random greys).
- Motion: 150-250ms ease-out on taps (Pressable exists), skeleton loaders (teal100) instead of spinners on rails.

---

## Where we are (unchanged from v1, dated 15 July 2026)

Backend near feature-complete (auth, catalogue, cart, booking, reports, health, wallet, subscriptions, support, notifications, AI, admin, technician, partner, SignalR); customer app covers the core journey with ~10 backend features not yet surfaced; payments gated "coming soon"; technician/partner/admin surfaces are skeletons. Pending verifications: BROKEN_FLOWS Flutter patches + two one-time DB updates. QA: all 5 findings fixed per FIXES_APPLIED.md.

## Web-informed improvements (kept from v1)

ABDM/ABHA + FHIR R4 reports (white-label moat), express-collection ETA promise + live tracking (Orange-Health pattern; our SignalR hub exists), WhatsApp-first lifecycle incl. report delivery, retention loops (score streaks, chronic re-test reminders, Health-SIP subscriptions, Wellio nudges), DPDP consent UX, COD + UPI-first checkout.

## Sources

- Healthians — [official site](https://www.healthians.com/) · [Google Play](https://play.google.com/store/apps/details?id=com.healthians.main.healthians&hl=en_IN) · [App Store](https://apps.apple.com/in/app/healthians-full-body-checkup/id1453011241)
- ABDM/ABHA — [ABHA integration guide](https://productgrowth.in/insights/healthtech/abha-integration-guide/) · [ABDM certification 2026](https://verticomply.com/compliance-info/abdm) · [M1 WASA checklist](https://isecurion.com/abdm-m1-wasa-testing-complete-guide.html)
- Market — [Orange Health](https://play.google.com/store/apps/details?id=in.orangehealth.patient&hl=en_GB) · [Tata 1mg](https://play.google.com/store/apps/details?id=com.aranoah.healthkart.plus&hl=en_IN) · [Zepto × Orange Health](https://www.digitalhealthnews.com/zepto-adds-home-diagnostics-to-boost-e-pharmacy-play) · [2026 diagnostics forecast](https://blog.creliohealth.com/beyond-metros-the-next-phase-of-indias-diagnostic-revolution-2026-forecast/)
- Retention — [health app habit loops](https://productgrowth.in/insights/healthtech/health-app-retention-guide/) · [patient engagement best practices](https://mindsea.com/blog/patient-engagement-apps-best-practices/)
