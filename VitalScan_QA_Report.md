# VitalScan (Bit2sky) — E2E QA & Code-Review Report

**Date:** 2026-07-06 · **Tester:** Fable (autonomous QA + review)
**Backend:** .NET 10 API on `:5001` (Development, `Auth__EchoEmailOtp=true`) · **App:** Flutter `bit2sky_customer`
**Method:** Live HTTP flows driven via browser `fetch` against `localhost:5001` (same-origin, `X-App-Source: flutter_android`) + source review of API/Application/Domain and Flutter providers/widgets. DB-level assertions are delegated to `smoke_test.sh` (see end) because the test sandbox cannot reach the Mac's Postgres/Redis.

---

## Summary

The core happy-path is healthy: email-OTP login issues a working JWT, all authenticated endpoints return 200 (the JWT signing/validation regression is fixed), cart writes INSERT correctly, booking snapshots the patient and reserves the slot, the cart clears on checkout, and both booking IDOR guards (foreign `addressId` / `familyMemberId`) reject. Family-member validation (missing gender/DOB **and** future DOB) is enforced. The Flutter home screen renders only from real data and hides empty sections.

**One High finding:** `GET /users/me` serializes the raw `User` domain entity, exposing `passwordHash`, `refreshTokens`, and `admin2faSecret` to any authenticated client. Plus two Mediums (no email validation on OTP send; guest-cart merge can silently drop items) and two Lows.

No Blocker (no data loss on the server, no auth-gate bypass, no working IDOR hole, no 401/500 on valid authed requests).

| # | Severity | Title | Layer |
|---|----------|-------|-------|
| 1 | **High** | `/users/me` returns raw User entity (passwordHash / refreshTokens / 2FA secret) | API + Domain |
| 2 | Medium | No email-format validation on OTP send → garbage accounts | API |
| 3 | Medium | Guest-cart merge silently drops items and clears local cart on failure | Flutter |
| 4 | Low | Slot capacity check + increment is a TOCTOU race (oversell) | API + DB |
| 5 | Low | Guest cart not persisted across app restart (acknowledged follow-up) | Flutter |

---

## Findings

### 1. [High] `GET /api/v1/users/me` exposes the full User entity, including secrets
**Layer:** API + Domain
**Repro:**
```
# after email-OTP login (token = accessToken)
curl -s -H "X-App-Source: flutter_android" -H "Authorization: Bearer $TOK" \
     http://localhost:5001/api/v1/users/me | python3 -m json.tool
```
**Expected:** A profile projection containing only client-safe fields.
**Actual:** The response `data` object includes `passwordHash`, `passwordChangedAt`, `refreshTokens`, `admin2faSecret`, `admin2faBackupCodes`, `admin2faEnabled`, `failedLoginCount`, `loginLockedUntil`, `isAdminPortalUser`, `otpAttemptCount`, `otpLockoutUntil`, `lastIpAddress` — the raw persistence entity.

For an OTP-only customer these secret fields happen to be `null`/empty, but the shape is unconditional: any **admin/password** user (or any user who later sets a password / enables TOTP) will leak their bcrypt hash, TOTP secret, and refresh-token collection to the client on every profile fetch.

**Evidence (code):**
- `Bit2sky.API/Controllers/UserController.cs:18` → `Me(...) => Ok(await _users.GetMeAsync(...))` returns the entity directly.
- `Bit2sky.Application/Abstractions/IUserService.cs:9` / `Services/UserService.cs:22` → `GetMeAsync` returns `Task<User>` (the domain entity, not a DTO).
- `Bit2sky.Domain/Entities/User.cs:34-47` → `Admin2faSecret`, `Admin2faBackupCodes`, `PasswordHash`, `RefreshTokens` are public; `grep -c JsonIgnore User.cs` = **0**.

**Suspected fix:** Project to a `UserProfileDto` in `GetMeAsync` (id, name, email, mobile, dob, gender, avatar, referralCode, membershipTier, familyMembers, addresses), or annotate the secret properties with `[JsonIgnore]`. A DTO is preferable so the domain entity is never on the wire.

---

### 2. [Medium] No email-format validation on OTP send → junk accounts can be created
**Layer:** API
**Repro:**
```
curl -s -H "X-App-Source: flutter_android" -H "Content-Type: application/json" \
     -X POST http://localhost:5001/api/v1/auth/email/otp/send \
     -d '{"email":"not-an-email"}'
# -> HTTP 200 {"success":true,"message":"OTP sent"}
```
**Expected:** `400` for a malformed email (the test brief lists “invalid email … → rejected”).
**Actual:** `200`. An `OtpRequest` row is written with `Email='not-an-email'`, and on verify `FindOrCreateByEmailAsync` will create a `core.users` row with that invalid address.

**Evidence:**
- `Bit2sky.Application/DTOs/AuthDtos.cs:8` → `public record SendEmailOtpRequest(string Email);` — no `[EmailAddress]` / `[Required]`.
- `Services/AuthService.cs:112` `SendEmailOtpAsync` trims/lowercases but never validates format; `:159` `VerifyEmailOtpAsync` → `FindOrCreateByEmailAsync` (`:175`) inserts a new `User` unconditionally.
- Contrast: `GoogleLoginRequest.DeviceInfo` **is** enforced (`/auth/google` with no `deviceInfo` → `400 "The DeviceInfo field is required"`), so DataAnnotations validation is wired up — `Email` was simply left unvalidated.

**Suspected fix:** Add `[EmailAddress]`/`[Required]` to `SendEmailOtpRequest.Email` (or a FluentValidation rule), returning `400` before an OTP row is written.

---

### 3. [Medium] Guest-cart merge silently drops items and wipes the local cart on failure
**Layer:** Flutter
**Repro (logic):** Add items as a guest → lose connectivity (or a `/cart/items` POST returns 5xx) → log in, which triggers `mergeGuestCartToServer()`.
**Expected:** Items that fail to merge are retained locally and/or the user is told the merge was incomplete.
**Actual:** Each item POST is wrapped in `catch (_) { }` (best-effort, no signal), and `clear()` is then called **unconditionally**. If some or all posts fail, those items vanish from both the server and the local cart with no user feedback — silent data loss.

**Evidence:**
- `lib/providers/cart_provider.dart:111-125` `mergeGuestCartToServer` — per-item `try/catch (_) {}`, then `ref.read(guestCartProvider.notifier).clear();` outside any success check.

**Suspected fix:** Track which items merged; only remove successfully-posted items, keep failures in the guest cart, and surface a snackbar if any item didn't merge. Alternatively, `refresh()` first and reconcile before clearing.

---

### 4. [Low] Slot capacity check and increment is a TOCTOU race (potential oversell)
**Layer:** API + DB
**Detail:** `BookingService.CreateAsync` reads the slot, checks `slot.Booked >= slot.Capacity`, then later does `slot.Booked++` and saves — with no row lock, `rowversion`/optimistic-concurrency token, or DB check constraint. Two concurrent bookings against the last seat can both pass the check and both increment, overselling the slot.
**Evidence:** `Bit2sky.Application/Services/BookingService.cs:60-118` (`FirstOrDefaultAsync` on Slot → capacity check `:64` → `slot.Booked++` `:115`).
**Suspected fix:** Use `SELECT … FOR UPDATE` (pessimistic) on the slot within the booking transaction, add a `xmin`/rowversion optimistic-concurrency token, or a DB `CHECK (Booked <= Capacity)` constraint so the increment fails safely under contention.

---

### 5. [Low] Guest cart not persisted across app restart (acknowledged follow-up)
**Layer:** Flutter
**Detail:** `guest_cart_provider.dart:7` notes persistence is “a follow-up.” A guest who adds items and restarts the app before logging in loses the cart entirely. Called out for tracking; matches the code comment, not a regression.
**Suspected fix:** Persist the guest cart to on-device storage (e.g. `shared_preferences`/Hive) keyed by test/package id.

---

## What passed (verified live unless noted)

- **JWT regression — FIXED.** Email-OTP `send → verify` returns a JWT; `GET /users/me` → **200** (not 401). All authenticated endpoints return 200: `/reports`, `/health/score`, `/wallet`, `/subscriptions`, `/support/tickets`, `/bookings`, `/packages`, `/tests/recommended`, `/home/sections`. Signing key (`JwtService.cs:20-55`, `PrivateKeyPem`) and validation key (`Program.cs:45-58`, `PublicKeyPem` else `PrivateKeyPem`) derive from the same dev key.
- **Identity.** Same email logging in twice → **same user id** (no duplicate). New email → one `core.users` row, `Mobile` NULL, unique `ReferralCode` (e.g. `B2S75283EAB`).
- **Negative auth.** Wrong OTP → **401**; replaying a used session → **401**; bogus Google `idToken` (with `deviceInfo`) → **401**, no crash. Google validation (`AuthService.cs:190-206`) checks `email_verified`, issuer `accounts.google.com`, and pins `aud` when configured, and shares `FindOrCreateByEmailAsync` with email login (one user per address).
- **Cart INSERT regression — FIXED.** `POST /cart/items` → `success:true`, 1 item, `payable` computed (299). Uses `_db.Set<CartItem>().Add(item)` (`CartService.cs:62`) — a real INSERT, not a phantom 0-rows; does not 401. Cart cleared to 0 items after checkout.
- **Family validation.** Valid member created; missing gender/DOB → **400**; **future DOB → 400** (stricter than the minimum asked).
- **Booking.** Created (`B2S0513413250`), slot returned (13 real rows for tomorrow), cart cleared, empty-cart booking → **400**. Patient snapshot fields (`PatientName/Gender/DateOfBirth`) written from the family member or self (`BookingService.cs:47-80`).
- **IDOR guards present.** Booking with a foreign/unknown `addressId` → **400**; foreign/unknown `familyMemberId` → **400** (`BookingService.cs:33-46`, both scoped `== userId`).
- **Flutter home — no fabricated data.** Every section hides when empty (`SizedBox.shrink()`): banner, services, active booking, health score, offers (explicitly avoids fabricating a `HEALTH20` coupon — `home_section_renderer.dart:1166`). FAB call number comes from `branding.supportPhone` (`home_screen.dart:84`); location from the default saved address with a “Set location” fallback (`:223-237`). No hardcoded prices/scores in widgets.

---

## Not yet verified — run `smoke_test.sh` on the Mac

My sandbox can't reach the Mac's Postgres/Redis, so these DB-level assertions and the real cross-user IDOR (which pulls another user's address from the DB) are covered by the provided script:

- `PatientName` snapshot persisted on the booking row.
- Slot `Booked` incremented (before vs after).
- New user row has `Mobile` NULL.
- IDOR with a **real** other user's `addressId` rejected (400/403).

```bash
cd "/Users/harshalpatil/Healthians app"
# API must be up on :5001 in Development with Auth__EchoEmailOtp=true, plus
# docker containers bit2sky-pg and redis running. The script FLUSHALLs redis itself.
bash smoke_test.sh        # exit 0 = all green
```
Paste the output back and I'll fold the DB-level results into this report.

> Note: live OTP send is rate-limited per email+IP; I hit a `429` mid-run creating a second user, which is why the real cross-user IDOR is deferred to the script (it flushes Redis first).
