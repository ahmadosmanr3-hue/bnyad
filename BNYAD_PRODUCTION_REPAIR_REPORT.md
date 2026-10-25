# BNYAD production repair — 25 October 2026

## Current status

Implementation and local validation are complete. Production deployment and
store release are **not complete**. Do not infer a release from a Git push or a
successful local build. This report will be updated after external verification.

Both repositories use `codex/bnyad-production-repair-2026-10-25`, based on the
latest fetched `codex/bnyad-stability-2026-10-13`:

- Flutter: https://github.com/ahmadosmanr3-hue/bnyad — base
  `b78fe50f0605b1ee10f13e195f76dd9aae07b583`.
- Backend: https://github.com/ahmadosmanr3-hue/bnyad-backend — base
  `b72b6efea19b58fe1c6a002b184801175efb7571`.

The authoritative deployment root is **bnyad-backend/vercel-api**. The historical
backend copy in the Flutter repository is not this release's backend; do not
deploy that stale mirror.

## Production mapping and rollback baseline

`https://nutrify-api-lovat.vercel.app` and `/admin` belong to the same existing
Vercel project, `nutrify-api`, not the separate failed `vercel-api` project.
Its configured Node runtime is 24. Git-triggered deployment is disabled.

The latest observed ready production deployment is
`dpl_68Xg458MDRf6gTsSikCjkQfTxfhN`,
https://nutrify-izgqgl9xs-ahmads-projects-67e04419.vercel.app, still built from
old commit `873d26e93b62044bfbc3cb37ddce61210bd17338`. The owner redeployed that
version while adding RevenueCat configuration. This is **not** a deployment of
the new repair branch. Public `/api/up` returned 200; `/api/ai/consent` returned
404. These checks did not sign in or write customer data.

Before promotion, record the final current deployment again, positively match
the target Neon database, capture a recoverable backup/PITR point, and apply only
the reviewed additive SQL. Do not run `prisma db push`, a seed or the empty
staging bootstrap against production. Promote only a checked candidate.

Rolling back the old backend after new authentication code has hashed sessions
can log migrated users out. Retain the new dual-format authentication reader in
an application rollback; leave additive tables in place. Do not restore an old
database snapshot over newer customer writes as a routine deployment rollback.

## AI: confirmed causes, repair and limits

Production serves the pre-AI backend: its consent endpoint is missing. Production
environment metadata also showed no `GEMINI_API_KEY`, `AI_ENABLED`, model or
spending configuration. A local mock success cannot repair those conditions.

Backend changes:

- `app/api/ai/generate/route.ts`, `lib/ai/provider.ts`: explicit disabled,
  missing-configuration, provider access, unavailable-model and provider-quota
  codes; redacted diagnostics and no newly added provider retries.
- `lib/ai/readiness.ts`, `app/api/admin/diagnostics/route.ts`: authenticated
  readiness/model/limits and actual aggregate usage, without credential values
  or a Google request.
- `app/api/up/route.ts`: optional read-only `?readiness=1` schema check, preserving
  the legacy plain health response.
- Existing auth, Premium checks, consent, nutrition validation, shared quotas,
  per-request controls and spending safeguards remain enforced.

Flutter `lib/services/api_service.dart`, `lib/utils/ai_strings.dart` and
`lib/widgets/ai_consent.dart` now distinguish an outdated backend, disabled AI,
missing configuration and provider quota in English, Arabic and Sorani. A failed
consent read no longer masquerades as the user declining consent.

The cumulative supervised Gemini ledger remains **21/21**. No live Google call
was made for these repairs. Production AI remains unverified and must stay off
until the owner separately approves activation, limits and supervised testing.
Do not advertise production AI as restored.

Before authorized activation, configure server-only variables from
`AI_RELEASE_HANDOFF.md`: `GEMINI_API_KEY`, `GEMINI_MODEL`, `AI_ENABLED`,
`AI_MONTHLY_BUDGET_USD`, token prices and per-user/rate/output limits. Use the
documented supported `gemini-3.5-flash-lite` only after project access and quota
are checked under a new authorization. Never put the key in Flutter.

## Push: confirmed causes and changes

Production's `FIREBASE_SERVICE_ACCOUNT_JSON` was scoped to Preview only, so the
production server had no configured Firebase credential. Its existing value has
now been scoped to both Preview and Production without reading or exposing the
secret. A new deployment is required for that change to take effect. The owner
also added `REVENUECAT_SECRET_API_KEY` to Production; existence is confirmed, but
the key's project/API compatibility is not yet functionally verified.

Firebase console confirms project `bnyad-16c1e`, sender `590340227341`, HTTP v1
enabled, the existing Android `com.bnyad.app` app and iOS `com.nutrify.bnyad` app.
Both development and production APNs auth-key entries exist for team
`632WWWM8AH`. Key presence is not proof of successful APNs delivery.

Source fixes:

- `lib/fcm.ts`: server-env-only credentials, OS-visible notification payload,
  Android channel/priority, APNs alert headers, redacted provider errors.
- `lib/notification-delivery.ts`: awaited bounded fanout, localized per-device
  content, real acceptance/failure counts and safe invalid-token removal.
- `lib/push-devices.ts`, `/api/fcm-token`, login/OTP routes, Prisma schema:
  authenticated multiple-device registry and token ownership transfer, while
  retaining legacy single-token compatibility. Logout removes only that device.
- `/api/admin/notifications`: validation, audience limit, shared send rate limit,
  persistent idempotency and send history. It no longer reports that a database
  insertion alone means a push was sent. Firebase acceptance is explicitly
  distinguished from a visible device notification.
- Flutter `push_service.dart`, `push_policy.dart`, `notification_service.dart`
  and `app_state.dart`: bounded APNs-token wait before FCM registration,
  registration-result checks, current-account token refresh, logout cleanup,
  duplicate background-alert prevention and local-notification tap navigation.

No visible FCM/APNs delivery has yet been verified on either physical device in
this repair. The local BNYAD Dev build deliberately disables optional production
Firebase services, so its working dashboard is not a push test. Samsung was not
connected. Verify foreground, background, locked and normally closed states,
record timestamps and inspect the tap destination before release. Force-stopped
OS states do not carry a delivery guarantee.

## Admin dashboard

`vercel-api/app/admin/page.tsx` and scoped `admin.css` retain existing backend
actions with a substantial responsive redesign: original BNYAD logo/teal,
sidebar/mobile drawer, overview metrics, responsive tables, pagination,
accessible dialogs, notification composer/history and real AI/settings
diagnostics. Historical revenue figures are labeled as recorded amounts, not
invented verified store income. Admin credentials remain in memory only.

Browser validation used the isolated local PostgreSQL database and fictional
records, with Google/Firebase traffic blocked. Six sections across widths 320,
375, 390, 430, 768, 1024 and 1440 yielded 42 layout checks with no document
horizontal overflow. A discovered 320px dialog clipping defect was fixed and
rechecked. Keyboard focus containment and Escape closing passed. One mock
notification was correctly recorded as history only, with zero provider
acceptances and `no_registered_devices`; it was not sent to customers.

Screenshots are in the backend repository's `docs/evidence/`: desktop overview,
320px overview and 320px user dialog. Local preview is
`http://localhost:3010/admin`, started by `scripts/admin-preview.ts`; it is not a
public deployment and uses only fictional local data.

## Store naming, signing and mobile builds

`AppBranding.storeName` and `STORE_METADATA.md` use the exact 30-character
**BNYAD: Calorie & Macro Tracker**. The launcher stays BNYAD. Store listing
metadata has not yet been saved or published. English/Arabic drafts accurately
avoid promising live production AI. The owner should review Arabic wording.

Existing Firebase native configuration was restored privately from the owner's
existing project and is ignored by Git. `tool/prepare_release_config.mjs` imports
only existing RevenueCat public mobile SDK keys into an ignored local file; it
never copies a Gemini/server key. Production API identity remains unchanged.

Android signing files are stored privately outside the repositories with owner-
only permissions. Gradle accepts optional private signing-file paths through
`BNYAD_ANDROID_SIGNING_PROPERTIES` and `BNYAD_ANDROID_KEYSTORE`; existing defaults
still work. No replacement keystore was generated.

The signed release candidate `1.0.2+14` built successfully after installing the
missing official Android SDK command-line tools. Package `com.bnyad.app`, target
SDK 36, min SDK 24, non-debuggable; Health Connect read permissions preserved.
Bundletool validation passed and JAR signature verification passed. The upload
certificate SHA-256 exactly matches the existing Google Play upload certificate:
`5B:0F:D7:E9:83:16:75:5E:C1:35:97:BE:A5:34:F7:57:52:AD:46:28:6A:40:7F:0A:B0:97:86:E0:99:CC:57:5B`.
The usual self-signed upload-certificate/no-timestamp warnings and a JAR streaming
manifest-order warning were recorded; the bundle passed Google's bundletool
structural validator. No upload has occurred.

Google Play showed live code 8 (1.0.0) and an existing draft code 13 (1.0.1).
That draft was preserved. Recheck the highest uploaded code before any upload;
do not discard another developer's draft or publish an unverified candidate.

The complete updated local-backed mock-AI iPhone Dev app was built, installed and
launched under `com.nutrify.bnyad.dev`. The owner confirmed dashboard, real Health
steps/calories and saved goal work. Existing App Store and Health Test apps were
not removed. The Mac's LAN address change was corrected using the existing local
CA; no health tracking or nutrition formula was changed.

App Store Connect is currently signed out, and owner sign-in was requested.
Only an Apple Development identity was available at inspection. A production
archive/export, signing validation, latest editable version/build check, upload,
review and release remain outstanding. Do not treat a development installation
as an App Store release.

## Tests and dependency changes

- Flutter analysis: no issues; 321 tests pass.
- Backend: 124 tests pass; TypeScript passes; Next.js production build passes.
- Next.js patched to 15.5.28, including its matching lockfile packages, for
  GHSA-2464-fhr4-w9xw / GHSA-p3m5-59mp-jv5r. Production npm audit: zero advisories.
- Real isolated local PostgreSQL integration passed auth, Premium, consent,
  all four mock AI operations, multilingual output, quotas and persistence.
  This did not call Google or use production customer data.
- Local preview uses separate build output directories so it cannot overwrite
  the running local iPhone backend's Next output.
- No changes to native HealthKit/Health Connect implementation, nutrition targets
  or the walking-calorie formula.

## Required rollout gates

1. Confirm the exact production Neon target and recoverable backup. The inspected
   Neon project has the original 13-table schema; new tables/notification column
   are absent. Vercel's sensitive DB URL cannot be read through this connection,
   so do not assume project identity from its name alone.
2. Review/apply, in order, only these additive migrations to the verified target:
   `db/20261013_auth_rate_limits.sql`, `db/20261013_ai_safeguards.sql`,
   `prisma/notification_translations.sql`, `db/20261025_push_delivery.sql`.
   They have been tested locally; **no production migration has been applied**.
3. Verify the existing Firebase service-account project and permissions, and the
   RevenueCat V1 secret/entitlement mapping. Never replace live store entitlements
   or grant client-claimed Premium as a shortcut.
4. Deploy the tested backend branch to the existing `nutrify-api` project with
   root `vercel-api`; check readiness, admin auth and existing-client compatibility
   before promoting. Keep AI off pending separate authorization.
5. Verify actual push delivery on both phones, purchase/restore compatibility and
   existing account/session behavior. Then create only the necessary store
   binaries, tied to the final source commits and checked private configuration.
6. Obtain owner Apple sign-in/signing approval as necessary. Update store metadata,
   submit tested binaries, and report each store's actual review/release status.

No billing was activated, no new paid resource purchased, no live Gemini request
made, no customer data modified, and no store release submitted by these repairs
so far. Environment scope edits are recorded above; they do not deploy code.
