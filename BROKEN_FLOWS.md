# Broken navigation flows — "services not working / land on the same screen"

Tested the running app + traced every home tap in code. The common symptom you saw —
tap a service, end up on the same tests list — is real. Root cause: several taps route
to `/tests` (or `/care`) instead of their intended screen.

## Root cause #1 (FIXED in code) — service tiles mis-routed in the DB seed

The live app renders **DB-seeded** quick actions (`content.quick_actions`). The seed
pointed 5 of 8 services at the wrong place, so they collapsed onto 2 screens:

| Service | Was | Now (fixed) |
|---|---|---|
| Blood Tests | `/tests` | `/tests` ✓ |
| Full Body | `/packages` | `/packages` ✓ |
| MRI & Scans | `/tests` | `/services/mri` |
| Doctor Consult | `/care` | `/services/doctor` |
| Diet Consult | `/care` | `/services/diet` |
| Vaccination | `/care` | `/services/vaccination` |
| Reports | `/reports` | `/reports` ✓ |
| Corporate | `/tests` | `/services/corporate` |

The app already ships a tailored `ServiceLandingScreen` for mri/doctor/diet/vaccination/
corporate — the seed just never pointed to it. Fixed in
`backend/src/Bit2sky.Infrastructure/Data/DataSeeder.cs`.

### Apply to the running DB (the seed only runs on an empty table)
```bash
docker exec bit2sky-pg psql -U postgres -d bit2sky -c "
UPDATE content.quick_actions SET \"DeepLink\"='/services/mri'         WHERE \"Label\"='MRI & Scans';
UPDATE content.quick_actions SET \"DeepLink\"='/services/doctor'      WHERE \"Label\"='Doctor Consult';
UPDATE content.quick_actions SET \"DeepLink\"='/services/diet'        WHERE \"Label\"='Diet Consult';
UPDATE content.quick_actions SET \"DeepLink\"='/services/vaccination' WHERE \"Label\"='Vaccination';
UPDATE content.quick_actions SET \"DeepLink\"='/services/corporate'   WHERE \"Label\"='Corporate';"
```
No app rebuild needed for this one — the app re-fetches quick actions from the API, so
re-opening Home picks up the new routes.

## Root cause #2 (Flutter — patches below, NOT yet applied)

More taps hard-coded to `/tests`, in `lib/features/home/home_section_renderer.dart` and
`home_screen.dart`. I did **not** edit these because another agent is actively editing
those same files right now — applying them concurrently would clobber its work. Apply
these once that agent is idle (or hand them to it):

1. **Popular Packages → "See all"** goes to `/tests` (line ~737). Should be `/packages`.
   ```dart
   onTap: () => context.push('/packages'),   // was '/tests'
   ```
2. **Package cards** open `/tests` (lines ~752, ~913, ~987) instead of the package.
   Should push the package detail, e.g. `/packages/${pkg.slug}` (add a
   `GoRoute('/packages/:slug')` if missing), or at minimum `/packages`.
3. **Search bar** pushes `/tests` (line ~296) — there's no real search screen. Either
   wire a search route or keep as a catalogue shortcut (low priority).

## Secondary robustness issue (optional)

`ServiceLandingScreen` does `_services[serviceId] ?? _services['corporate']` — an unknown
service id silently shows the **Corporate** page. Better to show a "not found" state so a
future bad deep link is visible rather than masquerading as Corporate.

## Flows that are fine

Bottom nav (Home/Care/Reports/Health/Profile via `AppShell` IndexedStack), banner CTAs
(Book Now→/tests, View Plans→/packages), Set location→/addresses, Call to Book (tel:),
Blood Tests→/tests, Full Body→/packages, Reports→/reports.

## Note on verification

The app currently in the Simulator is a pre-rebuild build, and I can't run the build
(the security model blocks me from typing into a terminal). After the seed SQL runs and
the app is rebuilt, tapping MRI/Doctor/Diet/Vaccination/Corporate should each open its own
landing screen. Tell me when it's rebuilt and I'll tap through all eight to confirm.
