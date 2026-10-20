# Local authenticated iPhone AI testing — 20 October 2026

This is a separate, mock-only development path for the COMPLETE existing app.
It is not a production deployment and does not enable Gemini for live users.
Android source, builds and devices are outside this task.

## Isolation and data flow

iPhone BNYAD Dev → private-LAN HTTPS → existing Next.js API → dedicated local
PostgreSQL cluster → simulated provider → unchanged response validators → UI.

The database is bnyad_local_iphone_20261020, on 127.0.0.1:55439 only.
Its independent cluster lives under the authoritative backend's ignored
vercel-api/.local-development/pgdata. Homebrew's default cluster is not used.
There are no production/Neon/Vercel connections, public tunnels or store actions.

Login verifies the fictional QA account's bcrypt password and issues the normal
hashed bearer session. Premium is a normal active custom subscription row
scoped to this local account, not a Flutter override or a real store purchase.
AI requests still require onboarded profile, Premium, explicit consent,
transactional usage accounting, cache admission and the normal validators.

The new APP_ENV=local-iphone guard requires NODE_ENV=development, explicit
local-test markers, no VERCEL, and the exact loopback database name/port.
Normal production and staging settings are not repurposed or loosened.
The HTTPS listener binds one RFC1918 interface, rejects public peers and
unexpected Host headers, and exposes only the required API paths. Admin,
setup, Next development UI and static-directory browsing are not exposed.
Keep both devices on a trusted private Wi-Fi; do not configure router forwarding.

## Zero live Gemini requests

BNYAD_LOCAL_AI_MODE=mock is mandatory for the local server. It substitutes a
transport into the existing Gemini request/response parser, then the route runs
the unchanged nutrition/allergy validators. Google calls are blocked by the
server's fetch policy and by the route's local execution guard.

Every app screen retains a persistent localized simulated-AI banner. Responses,
cache identities and usage logs also identify simulation. Input photos are not
recognized by the mock: the food/fridge fixture deliberately represents a tomato.
Recipe fixtures use specified catalog ingredients; daily fixtures use the
validated daily portions. Mock quality is not real model recognition/cooking QA.

The shared .gemini-development/requests.json remains at 19/20. It is never copied,
reset, initialized or incremented by mocks. The actual backend's local provider
requires that existing private ledger and uses the same exclusive-lock,
count-before-network DevelopmentBudget for any future supervised transport.
This build refuses all live generation regardless of environment edits; at 19,
it also refuses an incomplete two-call generation before token counting.
Further live testing requires separate owner approval and an explicit reviewed
change. No retry, model discovery, preflight or metadata request was made.

The real Gemini key remains in the existing ignored mode-600 private harness
file. The mock backend uses a dummy value; no real key is put in Flutter.
Do not load production env files, change the original allowance, enable billing,
or remove authentication/Premium/consent checks to make tests pass.

## Files and local tools

PostgreSQL 17 and mkcert were installed with Homebrew on this Mac. No service is
registered to start at login. No npm/Dart dependency was added.

- scripts/local-iphone-setup.ts creates a NEW cluster/schema/account only after
  explicit initialization arguments. It refuses an existing completed setup.
  The special resume option accepts only an empty, partially initialized local
  cluster; it does not reset or erase an existing application's data.
- scripts/local-iphone-server.ts starts the private HTTPS mock backend.
- scripts/local-iphone-integration.ts exercises real HTTPS/auth/database paths,
  using only the fictional account and explicitly tagged temporary quota fixtures.
- scripts/local-iphone-certificate.ts serves ONLY the public CA/profile for
  manual trust setup, not private keys, account files or directories. Its
  private-LAN certificate download listener expires after one hour.
- tool/run_local_backend_ios.sh builds/installs only com.nutrify.bnyad.dev.

Private .local-development/backend.env contains local-only DB credentials and
local flags. qa-account.txt contains the fictional QA login, not production
credentials. Read it privately on the Mac; never paste passwords into chat.
CA/server private keys, database files, logs and mobile-public.json stay ignored.

The public mobile build JSON contains ONLY LOCAL_API_BASE_URL (private HTTPS,
port 8443, /api) and LOCAL_CA_DER_BASE64 (single-line base64 DER public certificate,
never its private key). The client handles the historical DER loader and the
PEM loader used by this Flutter runtime by re-encoding the SAME certificate;
neither path permits an untrusted certificate or skips hostname checks.
After generating the local server cert with mkcert and the same private CAROOT,
write that public JSON privately and pass its absolute path to the build script.
A developer must independently approve/verify their own isolated local setup;
do not copy the owner's credentials or database.

## iPhone configuration

Separate entry point: lib/main_local_backend.dart.
Bundle: com.nutrify.bnyad.dev; native BNYADLocalBackend plist marker required.
Release, web, non-iOS and unmarked native builds refuse this entry point.
Production and the separate Health Test bundle are never installation targets.

The API client accepts exactly the configured private HTTPS origin and /api/
paths; redirects are disabled. Readiness must confirm matching local identity,
database availability, mock mode and liveGoogleAllowed=false.
The app trusts ONLY the supplied local CA for this client's TLS connection,
with certificate validity and IP hostname checks still enforced. There is no
badCertificateCallback, trust-all override or ATS arbitrary-load exception.
App-scoped trust avoids requiring device-wide root trust for this Flutter client.
If the optional Safari certificate profile was installed, remove “BNYAD Local
HTTPS Test Only” in iPhone Settings after testing; it contains one certificate,
not MDM/VPN/accounts. Never share the CA private key.

The existing App Store and Health Test identifiers are not overwritten.
The device inventory listed only BNYAD Dev among those three identifiers before
this installation; do not claim independent confirmation of the other installs.
No uninstall command is used.

The complete original app/screens/navigation/localization and native HealthKit
bridge are reused. HealthKit entitlement and dev signing are preserved.
Real steps remain native; no simulated health provider is used. Walking estimate
body values stay in the existing device-only health-profile key and are injected
separately from fictional server nutrition/weight data. Food allowance is not
increased by walking calories. Health consent/goals remain environment/account
scoped; a new backend identity may require connecting once/choosing its goal.
Previous offline settings/data are preserved, not deleted or copied as real
server records. The new API session/cache uses a separate Keychain account and
SharedPreferences namespace. Billing/push/notifications and external barcode
HTTP are disabled for this local test entry point.

## Schema/real integration defects found

1. Existing empty bootstrap SQL contained a captured Prisma upgrade banner.
   PostgreSQL rejected it and rolled the transaction back. Removed only the
   non-SQL banner; applied the corrected full baseline and the existing
   notification-translations additive SQL ONLY to the new local database.
   The old auth/AI additive scripts are already included in that baseline and
   were not blindly reapplied.
2. Prisma sends numeric raw-query parameters as bigint. PostgreSQL's two-key
   pg_advisory_xact_lock signature requires integer keys. Added explicit
   ::integer casts to user lock IDs in consent/reserve/complete. Transactional
   locking is preserved, not bypassed. No nutrition calculations were changed.

## Verification and remaining manual QA

Automated host checks: 105 backend tests, TypeScript checks, and 312 Flutter
tests, including local environment guards, exact-origin/redirect restrictions,
readiness mismatch, native authorization, mock failure paths, and preservation
of the shared request ledger. Flutter analysis is clean.

The real local HTTPS integration script passed normal password login, rejection
of wrong password/anonymous/no-Premium requests, consent and revocation, four
mocked AI operations with EN/AR/Sorani fields, unchanged daily nutrition bounds,
cache reuse, malformed/provider failure/429 paths, actual SQL daily/minute quotas,
food/water/weight and plan persistence, token use/logout invalidation and
unchanged 19/20 Google ledger. This uses a real isolated database, not Prisma
stubs. Native iPhone visual checks, actual HealthKit refresh and restart settings
require the user's device review; host tests do not prove these.

The iOS profile development build is development-signed with HealthKit and uses
the existing complete app, not Health Test. There are pre-existing MLKit/native
dependency/deprecation warnings; a successful build does not resolve those.
The final signed build was installed/launched on iPhone 15. Its private HTTPS
readiness request returned 200 after handling this runtime's certificate parser.
This confirms the native client can establish TLS to the local backend, not yet
that every screen has completed manual device review.

After login using the private fictional account, accept the AI consent when
prompted, generate one daily plan/recipe, test food/fridge UI with nonprivate
sample photos, switch EN/AR/Sorani, and review layout/wording. All outputs in
this session are simulated, even when their schema resembles prior Gemini output.
The consent explanation is the existing Google disclosure; in this mock build
no data is actually sent to Google.

Check steps versus Apple Health, optional local health profile, chosen goal,
restart session/language/goal persistence and unchanged food targets manually.
No new real Gemini result, iPhone live-AI test or production E2E claim is implied.

## Restart and release handoff

Run from authoritative bnyad-backend/vercel-api, in a clean shell without any
production DATABASE_URL. Start the existing local cluster (do not initialize again):

    /opt/homebrew/opt/postgresql@17/bin/pg_ctl -D .local-development/pgdata -l .local-development/postgres.log -o "-h 127.0.0.1 -p 55439 -k ''" -w start
    node --import tsx scripts/local-iphone-server.ts

Run the approved local-only integration suite with:

    node --import tsx scripts/local-iphone-integration.ts

Stop the backend with its process's interrupt. Stop only the dedicated cluster:

    /opt/homebrew/opt/postgresql@17/bin/pg_ctl -D .local-development/pgdata -m fast -w stop

Do not remove the cluster to reset tests. If the Mac's LAN address changes,
regenerate the private server certificate/public mobile build configuration
and rebuild the dev app. Keep the HTTPS API off public interfaces.

Normal backend production builds remain build-only verification; Git deployment
is disabled. No production migration, deployment, store submission, Android
installation or billing activation is authorized by this document.
