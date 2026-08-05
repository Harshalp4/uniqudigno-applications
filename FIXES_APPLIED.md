# VitalScan → Unique Diagnostic Centre — Fixes & Rebrand

All five QA findings are fixed and the app is rebranded to **Unique Diagnostic Centre**
with a recreated logo. Files changed are listed per item; build/verify steps are at the end.

## Fixes

### #1 (High) `/users/me` no longer leaks the User entity
- `Bit2sky.Application/DTOs/UserDtos.cs` — new `UserProfileDto` (client-safe allowlist) with `FromEntity`.
- `Bit2sky.API/Controllers/UserController.cs` — `Me` (GET) and `Update` (PUT) now return `UserProfileDto`, not the entity.
- `Bit2sky.Domain/Entities/User.cs` — `[JsonIgnore]` defense-in-depth on `PasswordHash`, `PasswordChangedAt`, `Admin2faSecret`, `Admin2faBackupCodes`, `RefreshTokens`.

### #2 (Medium) Email format validated on OTP send
- `Bit2sky.Application/DTOs/AuthDtos.cs` — `SendEmailOtpRequest.Email` now `[Required, EmailAddress]` (and `SendOtpRequest.Mobile` `[Required]`). Malformed emails now get 400 before any OTP/user row is created.

### #3 (Medium) Guest-cart merge no longer silently drops items
- `lib/providers/cart_provider.dart` — `mergeGuestCartToServer` removes each item only after it merges successfully (failures stay in the cart) and returns a `CartMergeResult`.
- `lib/features/auth/login_sheet.dart` — shows a snackbar when any item failed to sync.
- `lib/models/cart_models.dart` — added `CartItem.toJson`.

### #4 (Low) Slot oversell race closed
- `Bit2sky.Application/Services/BookingService.cs` — seat reservation is now an atomic conditional `ExecuteUpdateAsync` (`Booked = Booked + 1 WHERE Booked < Capacity`); the external payment call happens before it, and a 0-row result returns "Slot is no longer available".

### #5 (Low) Guest cart persists across restart
- `lib/providers/guest_cart_provider.dart` — persisted to a Hive box (`guest_cart`), hydrated on load, saved on add/remove/clear. Non-PHI data, so a plain box is used.

## Rebrand → Unique Diagnostic Centre

- New logo bundled: `mobile/bit2sky_customer/assets/images/logo.png` (recreated as a vector, exported to PNG). Registered in `pubspec.yaml`.
- `lib/features/splash/splash_screen.dart` — shows the logo on a white card (readable on the teal splash).
- Name updated everywhere user-facing: backend seed (`DataSeeder.cs`), TOTP issuer (`TotpService.cs`), email from/subject/body (`ResendEmailSender.cs`, `appsettings.json`), AI copilot prompt (`AiCopilotService.cs`), Flutter branding fallback (`branding_config.dart`), logout copy (`profile_screen.dart`).
- Theme colors left as-is (per chosen scope: name + logo only).

### ⚠️ One manual step — update the already-seeded branding row
The seeder only inserts branding when absent, so an existing DB still returns `app_name = "VitalScan"`.
Run once against the live DB:

```bash
docker exec bit2sky-pg psql -U postgres -d bit2sky -c \
  "UPDATE core.app_config SET \"Value\"='Unique Diagnostic Centre' WHERE \"Key\"='app_name';"
```

(The splash logo shows the brand regardless, but this makes `/config/branding` and the app title consistent.)

## Build & verify

```bash
# Backend
cd "/Users/harshalpatil/Healthians app/backend"
dotnet build            # expect 0 errors
dotnet test             # in-memory tests

# restart the API so the fixes are live (Development + dev OTP echo)
ConnectionStrings__Postgres="Host=localhost;Port=5432;Database=bit2sky;Username=postgres;Password=postgres" \
ConnectionStrings__Redis="localhost:6379" ASPNETCORE_ENVIRONMENT=Development \
ASPNETCORE_URLS="http://0.0.0.0:5001" Jobs__Enabled=false Auth__EchoEmailOtp=true \
nohup dotnet run --project src/Bit2sky.API --no-launch-profile > /tmp/api.log 2>&1 &

# App
cd "/Users/harshalpatil/Healthians app/mobile/bit2sky_customer"
flutter pub get
flutter analyze         # expect no issues
```

### Confirm the High fix after the API restarts
```bash
# login, then:
curl -s -H "X-App-Source: flutter_android" -H "Authorization: Bearer $TOK" \
     http://localhost:5001/api/v1/users/me | python3 -m json.tool
# passwordHash / refreshTokens / admin2faSecret must NOT appear
```

Then re-run `smoke_test.sh` for the DB-level assertions (patient snapshot, slot increment, IDOR).

> Note: I couldn't compile here (no .NET/Flutter SDK in this sandbox, and the running API is the pre-fix binary), so please run `dotnet build` + `flutter analyze` to confirm before shipping.
