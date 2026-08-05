# Unique Diagnostic Centre (Bit2sky / "VitalScan") — Technical Design Document

**Version:** 1.0 · **Date:** 8 July 2026
**Scope:** End‑to‑end architecture, data model, API surface, and user flows of our diagnostics/home‑collection app, plus a feature‑level gap analysis against the market reference product, **Healthians**.

> Terminology: the codebase carries three names — internal namespace **Bit2sky**, product placeholder **VitalScan**, and the current brand **Unique Diagnostic Centre**. They are the same product. "Healthians" throughout this document refers to the real, third‑party company we are benchmarking against, not our app.

---

## 1. System overview

The product is a **white‑label, at‑home diagnostics platform**: customers browse lab tests and health packages, add them to a cart, and book a home sample‑collection appointment (patient + address + time slot). A backend orchestrates catalogue, cart, booking, payment, reporting, wallet, notifications and admin operations. Field staff (phlebotomicians/"technicians") and referral partners have their own API surfaces.

There are three client surfaces backed by one API:

| Surface | Audience | Status |
|---|---|---|
| **Customer app** (Flutter, `bit2sky_customer`) | End customers | Primary focus; partially wired |
| **Admin portal** (API + `presso_admin`/web) | Ops, support, catalogue, finance | API complete; web separate |
| **Technician / Partner** (API) | Phlebotomists, referral partners | API present; app not in this repo |

---

## 2. Architecture

### 2.1 Backend — Clean/Onion architecture (.NET 10)

```
Bit2sky.API            → ASP.NET Core controllers, auth middleware, DI wiring
Bit2sky.Application    → services, DTOs, abstractions (use-cases, no infra deps)
Bit2sky.Domain         → entities + enums (pure model)
Bit2sky.Infrastructure → EF Core, Postgres, Redis, Razorpay, email, notifications
Bit2sky.Shared         → cross-cutting (app exceptions, result envelope)
```

- **Framework:** .NET 10, ASP.NET Core Web API, `[ApiController]` model validation.
- **Persistence:** PostgreSQL via **EF Core 9** (`Npgsql`). Schema‑segmented database: `core`, `content`, `catalogue`, `booking`, `commerce`, `comms`, `reports`, `admin`.
- **Cache / rate‑limit / OTP store:** Redis.
- **Auth:** JWT **RS256**; signing key in `JwtService`, validation key in `Program.cs`, both from the same PEM (dev key in `appsettings.Development.json`).
- **Payments:** Razorpay (order creation + HMAC‑SHA256 signature verification).
- **Email:** Resend (with dev OTP echo when no provider is wired).
- **Notifications:** multi‑channel orchestrator — WhatsApp (primary) → SMS (fallback), plus FCM push, email, in‑app.
- **API contract:** every response is a uniform envelope — `{ success, message, data, errors, pagination, correlationId }`. All customer calls require header `X-App-Source`.

### 2.2 Frontend — Flutter customer app

- **State:** Riverpod (`flutter_riverpod`).
- **Routing:** `go_router` with a global deep‑link allowlist validator (`DeepLinkValidator`) that redirects unknown paths to `/home`.
- **Networking:** `dio` client with the API envelope unwrapper and error mapping.
- **Local storage:** Hive (encrypted cache for PHI; plain box for the guest cart), `flutter_secure_storage` for tokens.
- **Maps/location:** `flutter_map` + `geolocator` + `geocoding` (address capture).
- **Security hardening:** `screen_protector`, `local_auth` (biometrics), `flutter_jailbreak_detection` (root/jailbreak check at splash).
- **Charts:** `fl_chart` (health‑score trends).
- **Auth SDKs:** `google_sign_in`.

### 2.3 Cross‑cutting concerns

- **Security:** PHI (name, mobile, email, DOB) AES‑256‑GCM encrypted at rest; RS256 JWT; per‑email + per‑IP OTP rate‑limiting in Redis; IDOR guards (ownership checks on address/family/booking); deep‑link allowlist; device root/jailbreak detection; screen‑capture protection.
- **Observability:** `correlationId` on every response.
- **Multi‑tenant/white‑label:** branding (name, tagline, colour, logo, support phone) served from `/config/branding`, DB‑driven with zero hardcoding.

---

## 3. Data model (domain entities)

Grouped by schema (representative, not exhaustive):

- **core:** `User` (+ referral code, membership tier, security fields), `Address`, `FamilyMember`, `Device` (FCM), `AuditLog`, `SecurityEvent`.
- **catalogue:** `Test`, `Package`, `Category`, `TestParameter`, lab/centre + `Pincode` serviceability.
- **booking:** `Booking` (patient snapshot, status lifecycle, reschedule count), `BookingItem`, `Slot` (per pincode/date, capacity/booked, service zones), `Subscription` (recurring test plans).
- **commerce:** `Cart`/`CartItem`, `Payment` (Razorpay), `Refund`, `WalletTransaction`, `Referral`, `Coupon`, `MembershipTier`.
- **comms:** `Notification` (channel + status), `WhatsAppTemplate`.
- **reports:** `LabReport`, report parameters, **`DietPlan`** (AI/curated plan tied to a report).
- **admin:** roles, permissions, `Partner`, `Technician`, AI prompts.

**Booking status lifecycle:** `Pending → Confirmed → TechnicianAssigned → SampleCollected → InLab → ReportReady → Completed` (plus `Cancelled`, `Rescheduled`, `NoShow`). *Note: the full lifecycle exists in the model; only a subset is currently driven by API endpoints and surfaced in the UI (see §6).* 

---

## 4. API surface (customer + admin + field)

**Customer (`/api/v1`):**
`config/branding` · `auth/email/otp/{send,verify}` · `auth/otp/{send,verify}` · `auth/google` · `users/me` (+ family, addresses, dashboard) · `tests`, `tests/popular`, `tests/recommended`, `tests/{slug}`, `categories` · `packages`, `packages/{slug}` · `slots` · `cart` (+ items, wallet points) · `bookings` (create, confirm, get, list, cancel) · `reports` (+ detail, parameters, download, request‑counselling) · `health/score` (+ history, vitals, steps) · `wallet` (+ transactions, tier‑benefits, redeem) · `subscriptions` · `group-bookings` · `support/tickets` · `notifications` (+ unread‑count) · `devices/register` · `content` (banners, **articles**, featured) · `ai` (Wellio copilot).

**Admin (`/api/v1/admin`):** users, bookings, coupons, refunds, analytics, notifications, packages, tests, ai‑prompts, wallet.

**Field:** `technician/*` (assignments), `partner/*` (dashboard, commissions).

---

## 5. End‑to‑end user flows

### 5.1 Onboarding & authentication
`/splash` (warms branding + auth bootstrap + root/jailbreak check) → `/onboarding` (first run) → `/login`.
Login is **email‑OTP‑first** (no phone required), with **mobile‑OTP** and **Google** as alternatives. `send` → `verify` returns a JWT. New/incomplete users are routed to **profile setup** (`/auth/setup`) before entering the app. Guests can skip via **Browse as Guest**.

### 5.2 Browse → cart
Home renders DB‑driven sections (banner carousel, "Our Services" quick actions, active booking, health score, popular packages, recommended, offers, family). Tapping a service/banner routes via a deep‑link. Catalogue (`/tests`, `/packages`) → test/package detail → **Add to cart**. Guests use an on‑device cart (Hive‑persisted); authenticated users use the server cart. On login the guest cart **merges** into the server cart (per‑item, failures retained).

### 5.3 Checkout → booking
Cart → checkout → **patient** (self or a family member) → **address** (owned) → **slot** (by pincode/date, capacity‑checked) → **create booking**. The booking **snapshots** patient name/gender/DOB, **atomically reserves** the slot seat, clears the cart, and (for online payments) creates a Razorpay order. Online‑first payment step: Razorpay sheet when keys are configured, graceful pay‑on‑collection fallback otherwise; COD bookings create directly as `Confirmed`. Wallet points debit atomically with the booking.

### 5.4 Post‑booking
`My Orders` lists bookings; a booking can be **cancelled** (before processing). **Reports** list → report detail → **download** / **request counselling**; a `DietPlan` can be attached to a report. Health tab shows **Health Score** (trend chart), vitals and steps.

### 5.5 Money & engagement
**Wallet** (HCash‑style points): balance, transactions, tier benefits, redeem (applied against cart payable). **Subscriptions** (recurring test plans). **Support** tickets with threaded messages. **Notifications** feed + unread badge.

### 5.6 Field & admin
**Technician**: assignment list / status updates. **Partner**: referral dashboard + commissions. **Admin**: catalogue, bookings, coupons, refunds, analytics, notifications, users.

---

## 6. Feature gap analysis vs Healthians

Legend: **✅ Have** (built & wired) · **🟡 Partial** (backend/data exists but not surfaced, or UI stub) · **❌ Missing**.

### 6.1 Core diagnostics journey

| Capability | Healthians | Us | Notes |
|---|---|---|---|
| Blood tests & full‑body packages catalogue | ✅ | ✅ | Tests, packages, popular, recommended, categories, **custom package builder** |
| Home sample collection booking | ✅ | ✅ | Patient + address + slot; slot reserved atomically |
| Time‑slot selection by area | ✅ | ✅ | Slots per pincode/date with capacity |
| Serviceability by pincode | ✅ | 🟡 | `Pincode`/`ServiceZones` fields exist; no pre‑booking serviceability check in UI |
| **Radiology / imaging** (MRI, CT, USG, X‑Ray, ECG, etc.) | ✅ | ❌ | We show a **static landing page** only; no scan catalogue, centre picker, or booking |
| Online payment | ✅ | 🟡 | P0a done: checkout sheet wired (razorpay_flutter), HMAC confirm, wallet combo, graceful no‑keys fallback; **needs Razorpay test keys for live-sheet testing** |
| Pay‑on‑collection (COD) | ✅ | ✅ | P0b done: COD bookings create as `Confirmed`; technician marks cash collected at `SampleCollected` (same transaction) |
| Reschedule booking | ✅ | ✅ | P0c done: `POST /bookings/{id}/reschedule` (window + limit config, atomic slot swap, tech reset) + reschedule sheet from order detail |
| Cancel booking | ✅ | ✅ | Before processing |
| Real‑time order/agent tracking | ✅ | 🟡 | P0d done: `BookingTrackingHub` broadcasts status changes; order‑detail screen tracks live (SignalR) with polling fallback. Map/ETA still pending (P2) |

### 6.2 Reports & clinical

| Capability | Healthians | Us | Notes |
|---|---|---|---|
| Smart reports (PDF) | ✅ | ✅ | Report list + detail + download |
| Historical trends / AI‑enriched report | ✅ | 🟡 | Health‑score trend chart exists; report‑level trend/AI evaluation not surfaced |
| Personalised diet plan | ✅ | 🟡 | `DietPlan` entity tied to report; **no generation flow / UI** |
| Free doctor consultation on reports | ✅ | 🟡 | "Request counselling" endpoint exists; **no consult scheduling** |
| Report delivery on WhatsApp / hard‑copy AWB | ✅ | 🟡 | WhatsApp channel + templates exist; delivery flow not wired |

### 6.3 Engagement, loyalty & content

| Capability | Healthians | Us | Notes |
|---|---|---|---|
| Wallet / cashback (HCash) | ✅ | ✅ | Balance, transactions, tiers, redeem |
| Referral program (refer & earn) | ✅ | 🟡 | `Referral` entity + referral code; **no earn/redeem flow or UI** |
| Coupons / offers | ✅ | ✅ | Admin coupons + cashback/offers surface |
| Health score ("Health Karma") | ✅ | ✅ | Score + history + breakdown |
| Vitals & step/calorie tracker | ✅ | 🟡 | Vitals + steps endpoints; tracker UI limited |
| Health/nutrition articles | ✅ | 🟡 | `content/articles` API exists; **no articles screen in app** |
| AI health assistant ("Wellio") | ✅ | ✅ | Our AI copilot is also named "Wellio" (`/ai`) |
| Family health management | ✅ | ✅ | Add members (medical fields), book per member |
| Recurring test subscription / "Health SIP" | ✅ | 🟡 | `Subscription` (recurring plans) in model; UI minimal |
| Corporate / B2B wellness | ✅ | 🟡 | Group bookings + Corporate landing; no full corporate portal |
| Push/WhatsApp/SMS notifications | ✅ | 🟡 | Multi‑channel orchestrator + FCM device register; **no notifications screen** |

### 6.4 Platform & trust

| Capability | Healthians | Us | Notes |
|---|---|---|---|
| Multi‑city coverage | ✅ (250+ cities) | 🟡 | Architecture supports it; data/serviceability is demo‑scale |
| NABL lab accreditation messaging | ✅ | ✅ | Shown in UI copy |
| Guest browsing before login | ✅ | ✅ | Guest cart + merge (a strength) |
| **White‑label / multi‑tenant branding** | ❌ (single brand) | ✅ | **We exceed Healthians here** — DB‑driven branding |
| Security hardening (PHI encryption, jailbreak, screen‑capture block) | — | ✅ | Strong posture |
| Admin ops portal (coupons, refunds, analytics) | ✅ | ✅ | API complete |

### 6.5 Summary

- **At parity / ahead:** catalogue, cart (with guest+merge), core home‑collection booking, wallet, health score, family, AI copilot, admin ops, **white‑label branding**, security hardening.
- **Biggest true gaps (Missing):** radiology/imaging booking, pay‑on‑collection (COD), live agent tracking UI, referral earn/redeem flow, in‑app notifications & articles screens.
- **"Last‑mile" gaps (backend ready, UI not wired):** online payment activation, reschedule, diet plan, doctor‑consult scheduling, WhatsApp report delivery, subscriptions UI, serviceability check.

---

## 7. Recommended sequencing (technical)

1. **Activate payments** (Razorpay UI + COD option) — unblocks real revenue; backend is ready.
2. **Wire the booking lifecycle** end‑to‑end: reschedule endpoint + order‑tracking screen driven by the existing status enum.
3. **Surface what already exists:** notifications screen, articles screen, subscriptions UI, referral earn/redeem — all have backend support.
4. **Fill true product gaps:** radiology/imaging catalogue + booking; diet‑plan generation; doctor‑consult scheduling.
5. **Serviceability**: pincode check before add‑to‑cart/booking.
6. **Hardening for scale:** slot‑reservation already atomic; add report WhatsApp delivery + AWB tracking.

---

## 8. Known issues carried from QA (see QA + BROKEN_FLOWS reports)

- Service quick‑action deep links were mis‑seeded (5/8 collapsed onto `/tests` or `/care`) — **fixed in seed**, SQL provided for the live DB.
- `/users/me` previously returned the raw entity incl. secrets — **fixed** (DTO + `[JsonIgnore]`).
- Email OTP had no format validation, guest‑cart merge could drop items, slot oversell race, guest cart not persisted — **all fixed**.
- Package "See all" / package cards / search route to `/tests` — **patches documented**, pending (Flutter files under concurrent edit).

*Sources for the Healthians benchmark are listed in the layman companion document.*


---

## 9. Status update — 15 July 2026 (P0 complete ∥ D1 consumed ∥ D2 shipped ∥ navy rebrand)

| Package | Status | Notes |
|---|---|---|
| P0a online payments | ✅ code + runtime-verified | Wallet clamp, stub order w/o keys, graceful fallback UI all exercised on simulator; real sheet awaits user‑supplied Razorpay test keys |
| P0b COD end‑to‑end | ✅ | COD creates `Confirmed`; `codCollected` required at collection → Payment `Paid` same transaction; admin `PUT /admin/bookings/{id}/assign-technician` added |
| P0c reschedule | ✅ | Config: `booking_reschedule_max` (2), `booking_reschedule_window_hours` (4); atomic seat swap via `IAppDbContext.TryReserveSlotSeatAsync`; UI sheet reuses extracted `SlotPicker` |
| P0d live tracking | ✅ | `BookingTrackingHub` (`JoinBooking` ownership‑checked, JWT via `?access_token=`), `IBookingEventsPublisher` fires on confirm/cancel/reschedule/assign/advance; order‑detail screen live + 15s polling fallback |
| D1 design system | ✅ consumed | Home, shell, header, and all new sections use `brandPaletteProvider` + design_system components; zero hardcoded teal in rebuilt surfaces |
| D2 home rebuild | ✅ | 13 seeded section rows (12 visible) w/ ConfigJson payloads; personalized header (wallet chip, bell+unread, cart count, rotating search); nav reseeded to Home·Care·Vitals·Profile; /notifications, /articles(+detail), /prescription stub routes |
| Rebrand | ✅ (v3) | DB-driven. v2 shipped logo-navy; v3 (user-approved from reference screenshots) switched to reference-teal: `primary_color` `#00A0A8`, `secondary_color` `#36B665` (offer-strip gradient end), tagline "Your health, our priority". Home + profile rebuilt to reference parity (pastel category tiles, mid cards, gradient offer strip, richer package cards, pill bottom-nav, R7 profile) |
| Seeding | ⚠️ note | Seeds/migrations apply via `dotnet run --project src/Bit2sky.API -- seed` (NOT on normal startup). Content reseeds are version-keyed (`content_seed_version`, currently 2) |
| Tests | ✅ 62 green | +COD (3), +reschedule (5), +hub (2) integration suites; smoke_test.sh extended to 25 checks (COD + reschedule + limit) |
| Known follow-ups | — | Legacy screens (catalogue/profile/wallet/booking wizard chrome) still hardcode teal → migrate in D3–D6; banner fallback images are Unsplash placeholders; category tile label "Consultations" wraps mid-word on small tiles (rename seed label or shrink type); technician app UI for `codCollected` flag pending |
