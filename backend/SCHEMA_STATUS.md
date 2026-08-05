# Database Schema — Build Status

Source of truth: **VitalScan Master Prompt v3, Section 6**.
v3 Section 6 defers the bulk of the schema to **"v2 Section 4"**, which is **not yet supplied**.
This file tracks exactly what is mapped and what is pending that document.

## ✅ Done — v3-complete subset (EF Core entities + configs + migration `InitialRbacAndSecurity`)

| Table | Entity | Notes |
|---|---|---|
| `admin.permissions` | `Permission` | Full. `action` CHECK constraint enforced. |
| `admin.roles` | `Role` | Full. |
| `admin.role_permissions` | `RolePermission` | Full. UNIQUE(role_id, permission_id). |
| `admin.user_roles` | `UserRole` | Full. UNIQUE(user_id, role_id); `assigned_by` FK. |
| `core.security_events` | `SecurityEvent` | Full. Both CHECK constraints + `idx_security_events_type (event_type, severity, created_at DESC)`. |
| `core.users` | `User` | **PARTIAL** — only the v3 security-addition columns. Base profile columns pending v2. |
| `core.refresh_tokens` | `RefreshToken` | **PARTIAL** — only the v3 security-addition columns (+ Id, UserId). Base token columns pending v2. |

Enums: `PermissionAction`, `SecurityEventType`, `SecurityEventSeverity` (mapped to exact DB strings).

## ⛔ Blocked on v2 Section 4 (not built — would require invented columns)

- `core.users` base columns (name, mobile, email, dob, address, …)
- `core.refresh_tokens` base columns (token hash, expiry, revoked_at, …)
- `core.audit_logs` — v3 gives immutability rules only, **zero columns** → no entity created.
- `core.app_config` — named only.
- `content.*` — `home_sections`, `quick_actions`, `onboarding_slides`, `nav_items`, `ai_prompts` (named only).
- `comms.whatsapp_templates` — named only.
- `commerce.membership_tiers` — named only.
- All of schemas `catalogue`, `booking`, `reports`, `health`, and the rest of `commerce` / `comms` / `content`.

## Migrations

- Generated via design-time factory (`AppDbContextFactory`), no DB connection required.
- Apply with: `dotnet ef database update -p src/Bit2sky.Infrastructure -s src/Bit2sky.Infrastructure`
  (set `BIT2SKY_DESIGN_DB` or a real connection string first).

> **To unblock the rest:** supply v2 Section 4, or authorize inference from Section 2 + Section 7.
