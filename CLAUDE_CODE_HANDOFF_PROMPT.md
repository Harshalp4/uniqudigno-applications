# Handoff prompt for Claude Code — Unique Diagnostic Centre (Bit2sky)

Copy everything inside the box below into Claude Code, started in the project
root (`/Users/harshalpatil/Healthians app`).

```
You are the lead engineer AND product designer on "Unique Diagnostic Centre" —
a white-label at-home diagnostics platform. Read DEVELOPMENT_RESTART_PROMPT.md
in the project root FIRST: it is the master spec (repo layout, design north
star, D-track design packages, P-track functional roadmap, non-negotiable
working rules, and the §DESIGN REFERENCE screen-by-screen spec). Everything
below supplements it with what a previous cloud session already completed, so
do NOT redo or overwrite that work.

════════════════════════════════════════════════════════════════════════
ALREADY DONE by the previous session (2026-07-15) — verify, don't rewrite
════════════════════════════════════════════════════════════════════════

A. Nav patches (BROKEN_FLOWS.md root cause #2) — APPLIED in
   mobile/bit2sky_customer/lib/features/home/home_section_renderer.dart:
   Popular-Packages "See all" + package cards → '/packages'; Recommended
   test cards + their "+Add" → '/tests/{slug}' via a new slug field on _Pkg.
   flutter analyze passed on this. Do not revert.

B. P0a payments — code complete on BOTH sides, NOT yet runtime-tested:
   Backend:
   - Infrastructure/Payments/RazorpayService.cs: real Orders API call
     (Basic auth KeyId:KeySecret, amount in paise) when Razorpay:KeyId +
     KeySecret are configured; deterministic local stub otherwise (dev).
     Exposes KeyId + IsConfigured via IRazorpayService.
   - IBookingService.cs records: CreateBookingRequest gained optional
     PaymentMethod ("online"|"cod"); CreateBookingResult gained nullable
     RazorpayOrderId + RazorpayKeyId.
   - BookingService.CreateAsync: creates a gateway order ONLY for online
     bookings with payable > 0; sets Payment.Method (CashOnCollection for
     cod) and Payment.CreatedAt; debits the wallet (with balance re-check +
     WalletTransaction row) in the same SaveChanges as the booking.
   - BookingService.ConfirmAsync: zero-amount (fully wallet-covered)
     bookings confirm without an HMAC; empty payment ids stored as null.
   - CartService.ApplyWalletPointsAsync: now server-authoritative — clamps
     requested points to min(cap%, wallet balance) instead of throwing, so
     the client can send its full balance.
   - appsettings.json: empty Razorpay section added (KeyId/KeySecret/
     WebhookSecret) — fill with test keys to activate the real sheet.
   Flutter (mobile/bit2sky_customer):
   - pubspec.yaml: + razorpay_flutter ^1.3.7 (run flutter pub get).
   - lib/features/booking/razorpay_checkout.dart (NEW): SDK wrapper —
     success/error/external-wallet handlers, brand name + theme color from
     the DB-driven BrandingConfig.
   - booking_screen.dart: online-first payment options; _placeOrder routes
     cod vs online; zero-payable confirms immediately; missing keyId
     degrades to pay-on-collection with a snackbar (no dead UI); failed or
     dismissed payment keeps the booking and flips the CTA to
     "Retry Payment · ₹X" (cart is cleared server-side, so it must never
     re-create the booking — _pendingPayment guards this).
   - confirmation_screen.dart + app_router.dart: '/booking/confirm?paid=1'
     renders a green "Paid" badge; unpaid keeps "Payment pending".
   - cart_screen.dart: "Use wallet balance" toggle (hidden for guests/empty
     wallets); cart_provider.applyWalletPoints(); booking_models.dart:
     razorpayKeyId + canPayOnline.

C. D1 design system — components exist but are NOT yet consumed by screens
   (this is why the app still LOOKS unchanged — D2 wires them in):
   - lib/core/theme/brand_palette.dart (NEW): BrandPalette.fromHex/-Primary
     derives a 50/100/700/800 tonal ramp at runtime from branding
     primary_color; headerGradient + ctaShadow helpers.
   - lib/providers/brand_palette_provider.dart (NEW): brandPaletteProvider
     watching brandingProvider, falling back to the static teal tokens.
   - lib/core/theme/app_colors.dart: semantic moneyAccent/-Light/-Dark
     aliases — amber is STRICTLY for offers/wallet/rewards.
   - lib/widgets/design_system.dart (NEW): PriceRow (₹final bold + ₹mrp
     strikethrough + "UPTO X% OFF" MoneyBadge), OfferStrip, FilterChipsRow,
     TrustBadgeRow, SkeletonBox.
   - lib/widgets/components.dart: SectionHeader upgraded to "Title +
     See all ›" spec (backward compatible — all call sites use title:).

D. QA/fix state: all 5 QA findings fixed earlier (FIXES_APPLIED.md);
   dotnet build + flutter analyze were green BEFORE the P0a/D1 batch;
   dotnet test, smoke_test.sh, and the P0a/D1 build have NOT been run yet.

════════════════════════════════════════════════════════════════════════
STEP 1 — VERIFY (do this before writing any code)
════════════════════════════════════════════════════════════════════════
1. cd backend && dotnet build && dotnet test           → must be green.
2. cd mobile/bit2sky_customer && flutter pub get && flutter analyze
                                                        → must be green.
   Fix any errors in the Section-B/C files yourself (they were written
   without a compiler available; expect at most small issues).
3. One-time DB updates (only if not already applied — check first):
   docker exec bit2sky-pg psql -U postgres -d bit2sky -c \
     "SELECT \"Label\", \"DeepLink\" FROM content.quick_actions;"
   If MRI & Scans/Doctor Consult/Diet Consult/Vaccination/Corporate don't
   point at /services/..., run the UPDATE block in BROKEN_FLOWS.md §root
   cause #1. Also:
   docker exec bit2sky-pg psql -U postgres -d bit2sky -c \
     "UPDATE core.app_config SET \"Value\"='Unique Diagnostic Centre'
      WHERE \"Key\"='app_name' AND \"Value\"<>'Unique Diagnostic Centre';"
4. Restart the API (Development, Auth__EchoEmailOtp=true, port 5001 — the
   exact command is in FIXES_APPLIED.md §Build & verify), run
   bash smoke_test.sh, then flutter run and tap through:
   cart → wallet toggle; booking wizard → "Pay online" first; placing an
   online order without Razorpay keys → graceful fallback notice.
   Note: cleanup — delete the leftover _staging_tmp/ folder in the project
   root (two tar files from the cloud session).

════════════════════════════════════════════════════════════════════════
DESIGN SYSTEM SPEC (D-track foundation — the full reference)
════════════════════════════════════════════════════════════════════════
North star: Healthians-level content richness and merchandising, executed
MORE premium — more white space, fewer competing gradients, one consistent
card language, no visual noise. The reference app mixes many gradients,
3D mascots, photos and emoji; we standardize to ONE illustration style,
gradients only on hero/offer surfaces, photography only in editorial.

── Color tokens (lib/core/theme/app_colors.dart + brand_palette.dart) ──
Brand ramp — NEVER hardcode in screens; use brandPaletteProvider, which
derives all four shades at runtime from /config/branding primary_color
(currently #00897B):
  palette.tint        (50-equivalent,  static teal50  #E0F2F1) chip bg,
                      light badges, input focus, icon containers
  palette.tintStrong  (100-equivalent, static teal100 #B2DFDB) skeletons,
                      divider accents
  palette.primary     (700-equivalent, static teal700 #00897B) CTAs,
                      links, active nav, icons, final price text
  palette.primaryDark (800-equivalent, static teal800 #00695C) pressed
                      states, gradient ends
  palette.headerGradient = primary→primaryDark topLeft→bottomRight — the
  ONLY sanctioned brand gradient (hero + package headers only).
Money accent — amber, STRICTLY for money surfaces (offers, discounts,
wallet, rewards, incentives) and nothing else:
  moneyAccent #FB8C00 · moneyAccentLight #FFF3E0 · moneyAccentDark #EF6C00
Status colors — health values ONLY (never decoration, never money):
  successGreen #43A047/#E8F5E9 · warningOrange #FB8C00/#FFF3E0 ·
  errorRed #E53935/#FFEBEE
Neutrals: background #F8FAFB · surface #FFFFFF · surfaceRaised #F4F6F8 ·
  borderDefault #E5E7EB · borderStrong #D1D5DB · textPrimary #1A1A2E ·
  textSecondary #6B7280 · textDisabled #9CA3AF · textInverse #FFFFFF
Text hierarchy uses textPrimary/textSecondary ONLY — no ad-hoc greys.

── Type scale (app_text_styles.dart — Inter via google_fonts) ──
displayLarge 28/800 · display 24/700 · h1 20/700 · h2 18/700 (section
titles) · h3 16/600 · h4 14/600 (card titles) · bodyLarge 15 · body 13 ·
bodySmall 12 · caption 11 · label 11/600 (badges) · button 13/600 ·
priceLarge 18/700 · priceStrikethrough 12 struck-through textSecondary.

── Spacing / radius / elevation (app_spacing.dart — 4pt grid) ──
Spacing: 2 4 6 8 12 16 20 24 32 48; screen gutter 16; card padding 16.
Radius: r8 chips/inputs · r12 icon tiles · r16 standard cards · r20 hero
cards · r100 pills/FABs.
Shadows (single-source, soft): shadow1 subtle rows · shadow2 cards
(default via AppCard) · shadow3 raised sheets · shadow4 modals. Cards are
white with EITHER a 1px borderDefault hairline OR a soft shadow — never
both stacked.
Motion: 150–250ms ease-out on taps (Pressable widget exists, scale
0.96–0.985); SkeletonBox loaders instead of spinners on rails.

── D1 components (lib/widgets/design_system.dart + components.dart) ──
USE THESE — do not reinvent per screen:
  PriceRow(price, mrp, large, palette)   → "₹1143  ₹4971̶  UPTO 76% OFF";
    final price in palette.primary, MRP struck through, MoneyBadge amber.
    The ONLY sanctioned price presentation; discount always framed as
    savings.
  MoneyBadge(text)                       → amber badge for offers/wallet/
    incentives ("70% OFF", "Get ₹500").
  OfferStrip(text, icon, onTap)          → slim full-width amber strip
    ("Get upto 70% OFF on all bookings"); text ALWAYS from DB payload.
  FilterChipsRow(options, selected, onSelect, palette) → single-select
    pill chips (36px), selected = filled palette.primary.
  TrustBadgeRow(badges, palette)         → tinted pills w/ verified icon
    (NABL, CAP, ISO — names from DB config); neutral/brand colors, trust
    is NOT a money surface.
  SkeletonBox(width, height, radius, palette) → pulsing tintStrong block.
  SectionHeader(title, onViewAll, actionLabel) → h2 title left,
    "See all ›" right (components.dart).
  AppCard / StatusBadge / QuickActionTile / Pressable — pre-existing,
    keep using them.
Persistent Call-to-Book FAB: pill, phone icon, bottom-right on every
browse screen, dials branding.supportPhone (already wired — keep it on
new screens).

── Hard rules ──
1 CTA style per card · max ~10-12 section types on the home feed ·
hide empty sections (no dead UI, no fabricated data) · all merchandising
content (banners, chips, section order, discount %s) DB-driven via
content.home_sections / quick_actions · zero Healthians branding, mascots,
photos, or copy.

════════════════════════════════════════════════════════════════════════
STEP 2 — BUILD NEXT (approved priority: P0 remainder ∥ D2)
════════════════════════════════════════════════════════════════════════
The user approved running the P-track and D-track in parallel.

D2 — HOME REBUILD (this is the visible change the user is waiting for).
DEVELOPMENT_RESTART_PROMPT.md §DESIGN REFERENCE R3 has the full observed
reference ordering; the adapted spec:
Target feed, top to bottom (each a SectionType + DB seed):
  1. personalized_header — "Hi {name}", location selector, wallet chip
     ₹balance (/wallet), bell + unread badge, cart icon. Sticky-ish.
  2. search — rotating placeholder cycling popular test names from the
     catalogue API ("Search for 'CBC'…"), mic icon.
  3. category_tiles — 3 tiles (Blood Tests / Scans / Consultations) each
     with a MoneyBadge "Up to X% off" chip; discounts from payload.
  4. prescription_upload — "Book via doctor prescription" banner (flow
     itself is D3; banner can deep-link to a stub route or hide).
  5. package_carousel_with_chips — FilterChipsRow (Popular/Vitamins/
     Allergy/Thyroid… from payload) + OfferStrip + package cards: name,
     "N tests", PriceRow, single BOOK NOW footer CTA.
  6. banner_carousel — dot indicators, campaign banners from DB.
  7. custom_package_banner — "Make your own package … Start now" →
     /packages/custom/builder (exists).
  8. persona_plans — Women / Men / Elderly care-plan cards.
  9. organ_rail — organ cards with "from ₹X" price + Book Now.
 10. concern_rail / lifestyle_rail — health & lifestyle concern cards.
 11. trust_block — TrustBadgeRow + counters from config (never invented
     numbers) + checkup-journey explainer row.
 12. refer_earn_banner (MoneyBadge accents) · articles_rail (image,
     title, summary, read-time, language from content DB).
 last_viewed — client-side from local history (Hive), no seed.
Key implementation constraints:
- Every new section = a new SectionType handled in home_section_renderer.dart
  + a content.home_sections DB seed row (type, title, payload JSON, sort).
  NEVER a hardcoded widget. Hide any section whose data is empty.
- Consume the D1 components (PriceRow, OfferStrip, FilterChipsRow,
  TrustBadgeRow, SkeletonBox, SectionHeader) and colors via
  brandPaletteProvider — no hardcoded teal/amber hexes in new code.
- Ship seeds for (cap the default feed at ~12 sections, premium ≠ busy):
  category_tiles (discount chips from DB), prescription_upload banner,
  package_carousel_with_chips (+ offer strip), banner_carousel,
  custom_package_banner, persona_plans (Women/Men/Elderly), organ_rail,
  concern_rail, lifestyle_rail, trust_block, refer_earn_banner,
  articles_rail. last_viewed is client-side (local history, no seed).
- Personalized header per R3: Hi {name}, location selector, wallet chip
  (₹balance from /wallet), notification bell + unread badge, cart icon;
  rotating search placeholder from popular tests + mic icon.
- Bottom nav reshape: nav is DB-driven via /nav/bottom (navItemsProvider →
  app_shell.dart _pageFor). Reseed to 4 tabs: Home · Care · Vitals ·
  Profile. Map '/health' → Vitals label; fold Reports entry points into
  Profile (row exists) and Care. Update _pageFor + deep_link_validator if
  routes change. The '/care' tab currently maps to CatalogueScreen — leave
  that until D3 builds the real Care tab.

P0 remainder (in order):
- P0b COD end-to-end: the cod plumbing exists through booking creation;
  add technician/ops mark-paid on collection (Payment.Status → Paid,
  Method CashOnCollection) and reflect it in the customer tracker.
- P0c Reschedule: endpoint honoring RescheduleCount + atomic slot
  re-reserve (mirror the conditional ExecuteUpdateAsync pattern in
  BookingService.CreateAsync), + UI from the booking detail.
- P0d Order tracking screen on BookingTrackingHub (SignalR) with the
  status lifecycle; the BookingTracker widget already exists.
- Razorpay: user must supply test keys in appsettings (or env) before the
  real sheet can be tested; with keys present, test a full online booking
  and the HMAC confirm.

D-track after D2 (in order, from the master prompt — summaries):
- D3 Care tab: prescription-upload booking (upload Rx → ops queue in
  admin), lifestyle-based test entries, HealthKarma-style health-score
  screen (gauge + High/Medium/Low risk buckets + peer percentile +
  suggested tests from the recommendation service), doctor/dietician
  consult cards. Omit supplements unless the catalogue supports it.
- D4 Vitals tab: diet-plan card (kcal, ideal weight, BMI), track-your-diet,
  health trackers (steps/sugar/BP/weight → existing /health endpoints),
  report-driven "needs improvement" parameter chips with real values,
  quick-help (call + chat).
- D5 Profile: wallet strip, corporate verification, My Wallet/Bookings/
  Reports/Appointments/Family (per-member health score; add-member
  incentive badge ONLY if a live wallet promo exists in DB), Addresses,
  WhatsApp channel join, Refer & Earn, Help, Privacy, Logout, version.
- D6 Catalogue: location/pincode selector, browse-by-concern chips,
  packages-by-gender&age grid, popular tests with inline "+" add, advisor
  call banner; detail screens get tests-included, fasting/report-time/
  recommended-for meta rows, PriceRow, sticky Add to Cart.

════════════════════════════════════════════════════════════════════════
NON-NEGOTIABLE RULES (from the master prompt — enforce everywhere)
════════════════════════════════════════════════════════════════════════
- White-label: zero hardcoded brand names/colors/prices/coupons/phones —
  everything from /config/branding, AppColors/BrandPalette, and DB content.
  Never copy Healthians branding, mascots, photos, or copy.
- Never fabricate UI data; sections render from API/DB and hide when empty.
- Keep the response envelope + X-App-Source contract; DTOs on the wire;
  IDOR ownership checks; atomic slot mutations.
- Amber = money only; status colors = health values only; one CTA style
  per card; 4pt spacing grid; radius 12/16/20; soft single-source shadows.
- After each work package: dotnet build + dotnet test + flutter analyze +
  smoke_test.sh, and update the status tables in DESIGN_TECHNICAL.md.
  If a doc contradicts code, trust the code and fix the doc.

Start with STEP 1, report what you find, then proceed to STEP 2.
```
