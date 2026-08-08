# Play Store release — Unique Diagnostic Centre (customer app)

Package: `com.uniquediagnostic.customer` · Version: `1.0.0+1`

## Building the bundle

```powershell
cd mobile\bit2sky_customer
.\scripts\build_release.ps1 -ApiBaseUrl "https://api.<your-domain>/api/v1"
```

Output: `build\app\outputs\bundle\release\app-release.aab` — upload this to Play.
(`scripts\build_release.sh` is the older bash version and emits an APK, which Play
does not accept. Use the PowerShell script for store builds.)

Optional flags:
- `-CertPins "<b64sha256>,<b64sha256>"` — enables leaf-cert pinning. Include a
  backup CA pin, or a cert rotation bricks every installed app.
- `-AlsoApk` — additionally emits a universal APK for sideloaded QA.

The build is obfuscated. Symbols land in `build\debug-info\android` — archive them
per release and upload to Play, or crash reports are unreadable. Never ship them.

## Signing

`android\upload-keystore.jks` + `android\key.properties` (both gitignored).

**Back both up somewhere off this machine.** Losing them means you cannot ship an
update under this listing without a Play-side upload-key reset.

Upload key SHA-1: `48:9E:91:E8:09:7D:D1:8E:4E:84:00:E5:F4:FC:03:4F:69:B1:6E:C4`

Note Play App Signing re-signs the bundle, so the certificate users' devices see
is Play's, not this one. Anything keyed to a signing fingerprint (Google Sign-In,
Maps, attestation) must register **Play's app-signing SHA-1** — visible under
Release → Setup → App signing after the first upload — in addition to the upload
key above for local testing.

## Blockers before this listing can go live

1. **Backend is not deployed.** The API must be reachable over public HTTPS
   before the build is functional. `-ApiBaseUrl` rejects non-HTTPS: Android blocks
   cleartext by default and the app declares no cleartext exemption.

2. **Google Sign-In points at a borrowed Google Cloud project.**
   `lib/features/auth/google_sign_in_helper.dart:11` carries a client ID noted in
   its own comment as "PRESSO's project for now". Create a Google Cloud project for
   this app, register `com.uniquediagnostic.customer` with the Play app-signing
   SHA-1, and replace `googleServerClientId`. The backend validates tokens against
   this audience, so it has to change on both sides together. Until then Google
   sign-in fails on any real install.

3. **Razorpay keys.** Live keys go in the backend (`Razorpay:KeyId`/`KeySecret`),
   not the app — the app receives the key ID per booking. With the section empty
   the app degrades to pay-on-collection, which ships fine but means no online
   payment. Test the full online flow before release.

## Play Console setup

- **Data safety** — this app collects health data, precise location, name, phone,
  and email. Health data is a sensitive category; expect the declarations to be
  scrutinised and the first review to run long.
- **Health apps declaration** — Play requires a separate form for apps handling
  medical/health information.
- **Privacy policy URL** — mandatory, and must specifically cover the health data
  handling. Must be live before submission.
- **Permissions rationale** — location is declared `required="false"` and used only
  for address capture during at-home collection. Say exactly that.
- **Payments** — diagnostic tests are real-world services, so Razorpay is exempt
  from Play Billing. No action needed beyond honest disclosure.
- **Content rating** questionnaire, screenshots (phone + 7"/10" tablet if you
  declare tablet support), feature graphic, short + full description.
- **Target API level** — currently built against the Flutter default for SDK 36,
  which satisfies the present Play requirement.

Start on the **internal testing** track. It skips most of the review queue and
lets you validate the live backend against a real Play-signed build before
anything is public.

## Android toolchain — pinned, do not bump casually

**AGP is pinned to 8.13.0 on Gradle 8.14.3, and must stay on AGP 8.**

The repo arrived on AGP 9.0.1 / Gradle 9.1.0, which cannot build:

- Flutter 3.44.8's Gradle plugin casts the Android extension to the old-DSL
  `AbstractAppExtension`, so it fails to apply under AGP 9's new DSL
  (`android.newDsl=true`).
- AGP 9's built-in Kotlin (`android.builtInKotlin=true`) *requires* that new DSL.
- But `screen_protector` (1.5.2 and 1.5.3 alike) skips applying `kotlin-android`
  whenever AGP is 9+, assuming built-in Kotlin will compile it. With built-in
  Kotlin off, its sources never compile and the app fails to link
  `ScreenProtectorPlugin`.

So on AGP 9 the two flags are mutually exclusive and every combination fails.
AGP 8.13 is the newest release that works with Flutter 3.44.8, and it supports
`compileSdk 36`. Revisit only when Flutter ships new-DSL support.

Other build config that exists for a reason:

- `android/gradle.properties` → `kotlin.incremental=false`. Kotlin's incremental
  compiler memory-maps its caches and can't release them on Windows, failing
  plugin modules with "Could not close incremental caches". Release builds are
  clean builds, so incremental compilation buys nothing here.
- `android/build.gradle.kts` forces `compileSdk 36` on all subprojects. Several
  pub plugins still pin 33 while the AndroidX artifacts they pull in
  (exifinterface, core, biometric) require 34+. Their sources are in the
  read-only pub cache, so it has to be done from the root build.
- `proguard-rules.pro` carries `-dontwarn com.google.android.play.core.**`. The
  Flutter engine references Play Core for deferred components; this app has none
  and doesn't depend on Play Core, so R8 otherwise fails on the absent classes.
- `flutter_jailbreak_detection` is vendored under `third_party/` — see the README
  there.

## Bundle size

~55 MB, which is expected and fine. About 88 MB uncompressed is
`BUNDLE-METADATA` — native debug symbols and the ProGuard map that Play uses to
symbolicate crashes. None of it reaches devices. A device downloads one ABI, so
the real install is roughly 20 MB.

## Changes made to reach a shippable configuration

- Package renamed `com.bit2sky.bit2sky_customer` → `com.uniquediagnostic.customer`
  (namespace, applicationId, Kotlin package). Permanent once published.
- Real release signing wired up; was signing with the debug key, which Play rejects.
- R8 minify + resource shrinking enabled, with keep rules for Razorpay's JS bridge
  and payment callbacks (`android/app/proguard-rules.pro`).
- `MainActivity` now extends `FlutterFragmentActivity`. `local_auth` needs a
  `FragmentActivity` host; under plain `FlutterActivity` the plugin throws,
  `BiometricService.authenticate()` catches it and returns `false`, and the
  biometric gate on reports and the family vault fails closed for every user.
- `INTERNET` permission added to the main manifest. It was declared only in the
  debug manifest, so release builds had no network access at all.
- Added `ACCESS_NETWORK_STATE` (Razorpay connectivity check) and `USE_BIOMETRIC`.
- Added `<queries>` for `tel:` and `https:`. Android 11+ hides unlisted handlers,
  so the call-to-book FAB and report-PDF links were silently no-ops.
- Location marked `required="false"` so the listing isn't hidden from GPS-less devices.
- Launcher icons generated from `assets/icon/app_icon.png` (were still Flutter defaults).
- Android toolchain moved from the unbuildable AGP 9.0.1 / Gradle 9.1.0 to
  AGP 8.13.0 / Gradle 8.14.3, and `flutter_jailbreak_detection` vendored — see
  the two sections above.
- `analysis_options.yaml` excludes `third_party/**` so vendored code isn't linted.
