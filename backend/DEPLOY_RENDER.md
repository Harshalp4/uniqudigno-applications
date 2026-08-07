# Deploying the API to Render

Blueprint: `render.yaml` (repo root). Region **Singapore** — Render has no India
region, so expect ~50–80 ms extra round trip for Indian users.

## What gets created

| Service | Type | Plan |
|---|---|---|
| `uniqudigno-postgres` | Postgres 17 | `basic-256mb` |
| `uniqudigno-redis` | Key Value | `starter`, private (`ipAllowList: []`) |
| `uniqudigno-api` | Docker web service | `starter` |

Roughly $50–60/month. Do **not** use the free Postgres plan: it expires after 30
days and takes the database with it.

## Deploy

1. Push this repo to GitHub.
2. Render Dashboard → **New → Blueprint** → pick the repo. It reads `render.yaml`.
3. Render prompts for every `sync: false` variable — see below.
4. Deploy. `preDeployCommand` runs `dotnet Bit2sky.API.dll migrate` to apply the
   11 EF migrations before the new instance takes traffic.

Seeding is deliberately **not** part of the deploy. Run it once, manually, from
the service shell, and only if you want the reference/demo rows:

```
dotnet Bit2sky.API.dll seed
```

## Secrets to supply

| Variable | Notes |
|---|---|
| `Jwt__PrivateKeyPem` | **Generate fresh.** See "Rotate the JWT key" below |
| `Jwt__PublicKeyPem` | Public half of the same keypair |
| `PhiEncryption__Key` | base64 32-byte AES-256. **Generate once and back it up** — changing it makes existing encrypted PHI unreadable |
| `ConnectionStrings__AzureBlob` | External object storage — see "Blob storage" |
| `Razorpay__KeyId` / `__KeySecret` / `__WebhookSecret` | From the Razorpay dashboard |
| `Email__ResendApiKey` / `Email__FromAddress` | Resend |
| `Anthropic__ApiKey` | Claude API |
| `Cors__AllowedOrigins__0` | Admin portal origin. Add `__1`, `__2` for more. Mobile apps don't use CORS |

PEM values are multi-line. Paste them into Render's dashboard as-is — its env var
editor accepts newlines. If you script it instead, escape them as `\n`.

Generate the pair with:

```bash
openssl genrsa -out jwt_private.pem 2048
openssl rsa -in jwt_private.pem -pubout -out jwt_public.pem
openssl rand -base64 32          # PhiEncryption__Key
```

## Rotate the JWT key — required before go-live

`appsettings.Development.json` has a real RSA private key committed to git
(commit `6529e95`). It is recoverable from history even if deleted, so it must be
treated as compromised. Generate a new keypair for every environment, put it in
Render, and never reuse the committed one.

## Blob storage

Render has no S3 equivalent, and `AzureBlobService.cs` is the only storage
implementation. Two options:

- **Keep an Azure Storage account** and point `ConnectionStrings__AzureBlob` at
  it. Works fine from Render, a few dollars a month, no code change.
- **Swap to S3/R2** by writing a new `IBlobService`. Cheaper and removes the last
  Azure dependency, but it's real work and touches how reports (PHI) are stored.

Nothing else needs Azure — `Azure__KeyVault__Uri` is deliberately empty, and
`Program.cs` only registers the Key Vault provider when it's set, so all secrets
come from Render's environment.

## What the deployment already handles

- **Forwarded headers.** Render terminates TLS at its edge and forwards plain
  HTTP. Without honouring `X-Forwarded-Proto`, `UseHttpsRedirection` would 307 to
  https, the proxy would forward as http again, and every request would loop.
  `Program.cs` reads the header before the redirect runs.
- **Connection string formats.** Render publishes `postgresql://` and `redis://`
  URLs; neither Npgsql nor StackExchange.Redis parses those.
  `ConnectionStringNormalizer` converts them at startup and passes anything
  already driver-native through untouched, so local and Azure configs still work.
  Covered by `ConnectionStringNormalizerTests`.
- **Port binding.** The container listens on `0.0.0.0:8080` and `PORT` is set to
  match, so Render's health check and the listener agree.
- **Health check** at `/health`.
- **Swagger is off.** It's gated to Development/Staging, and Render runs
  Production.
- **The committed dev key never reaches the image** — `.dockerignore` excludes
  `appsettings.Development.json` from the build context. That is damage control,
  not a substitute for rotating the key.
- **Hangfire is off** (`Jobs__Enabled=false`), matching `appsettings.json`.

## Known limits

**Stay at one instance.** `AddSignalR()` has no Redis backplane, so with two
replicas a booking update published on instance A never reaches a client
connected to instance B. Scaling up silently breaks live tracking. Adding
`.AddStackExchangeRedis(...)` — the Redis instance already exists — is the fix.

**Background jobs don't run.** Cashback crediting, group-booking expiry,
subscription reminders and SLA escalation are all disabled. Fine while none of
those features are live; before any of them ship, deploy this same image as a
second service with `Jobs__Enabled=true` rather than enabling jobs in the web
tier.

**CI is red and has no deploy job.** The workflow stops at `build-staging` plus
an `echo` checklist. It also fails on a secrets grep that matches key *names*
(so `ResendApiKey` trips it even when empty) and on five pre-existing `CS8604`
nullable warnings under `-warnaserror`. Render deploys on git push regardless, so
this doesn't block launch — but CI isn't gating anything right now.
