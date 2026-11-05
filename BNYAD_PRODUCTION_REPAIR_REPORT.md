# BNYAD production repair — 26 October 2026

## Current status

The repaired production backend is deployed and its schema is ready. Final
physical-device/purchase regression and store release are **not complete**.
The owner explicitly approved the mobile release with AI disabled for everyone.
Internal TestFlight build 15 is installed and verified. Candidate build 16 was
uploaded successfully to Apple; processing/TestFlight checks remain pending.
It has not been submitted for App Review or Google Play.
Do not infer a public release from a Git push, upload or successful local build.

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

The pre-repair rollback baseline is
`dpl_68Xg458MDRf6gTsSikCjkQfTxfhN`,
https://nutrify-izgqgl9xs-ahmads-projects-67e04419.vercel.app, still built from
old commit `873d26e93b62044bfbc3cb37ddce61210bd17338`. The owner redeployed that
version while adding RevenueCat configuration. Its consent endpoint returned 404.

On 26 October the repaired backend commit
`8082a089f85ef294471ef9ff8c106e17dd437c33` deployed as
`dpl_ApsWmfypScTPQJc94BCtED2Lmqjz` to the existing Production project.
Public `/api/up` returned 200; `/api/up?readiness=1` returned ready with that
revision. AI consent, barcode and admin diagnostic routes correctly returned
401 without authentication; `/admin` returned its login page. The owner signed
into the repaired admin and its authenticated settings reported schema Ready,
push credentials Configured and store verification Configured. Credential
presence alone is not functional purchase verification.

The production database mapping was verified without reading secrets or customer
rows: nonexistent-token authentication probes returned 401 and increased the
Neon api_tokens table scan counter by exactly 3, then exactly 5. This positively
matched project `small-frog-96915412`, main branch `br-cold-heart-awt4ozzt`,
database `neondb`. A recovery branch `backup-before-prod-repair-20261025`
(`br-dawn-darkness-awr9l47b`) was created within the existing Free limits, with
expiry 1 November 2026 at 21:00 GMT+3. Existing PITR is six hours. No production
schema changes were made before that backup. The five reviewed additive SQL
files were then applied in one explicit transaction on the verified main branch,
with lock/statement timeouts. COMMIT succeeded; a separate read-only query verified
all seven required tables and both new columns. No seed, reset, destructive SQL
or subscription/nutrition-value update was performed. The recovery branch was
not migrated. Schema-only evidence: backend `docs/evidence/production-schema-readiness.png`. Do not run `prisma db push`, a seed or the empty
staging bootstrap against production. Promote only a checked candidate.

Rolling back the old backend after new authentication code has hashed sessions
can log migrated users out. Retain the new dual-format authentication reader in
an application rollback; leave additive tables in place. Do not restore an old
database snapshot over newer customer writes as a routine deployment rollback.


Final availability/configuration deployment: `dpl_C9Z87f4d1ANLULjjYw4DrW8dKRAW`,
https://nutrify-i789bhf9v-ahmads-projects-67e04419.vercel.app, source
`0b0726f61349887b33e3134b9662a182c95943c0`. Public readiness returned 200 with
that revision. Authenticated admin reports model `gemini-3.5-flash-lite`, only
`ai disabled` as the AI blocker, 3/day, 1/minute and $1/month safeguards; production
AI accounting remains zero. The old `APP_ENV` value incorrectly labeled this
Production target as development; it was corrected to `production` and deployed.
`NODE_ENV=production` had already enforced production authentication; no auth
protection was bypassed by that old display label. Secret type/scope is verified;
provider access/quota is not claimed tested by configuration alone.
Evidence: backend `docs/evidence/production-ai-disabled-settings.png`.

## AI: confirmed causes, repair and limits

The old production deployment lacked the consent endpoint and AI configuration.
The repaired endpoint is now deployed. The owner approved keeping live AI off
for this release on 26 October. Vercel now explicitly has `AI_ENABLED=false`,
`GEMINI_MODEL=gemini-3.5-flash-lite`, prepared model prices, a $1 monthly
application safeguard, 3 requests/user/day and 1 request/user/minute. This does
not activate billing. The owner saved `GEMINI_API_KEY` privately as a Production Secret. Only metadata
was inspected; its value was not read, printed or committed.
No new Google request is authorized or made; the development ledger stays 21/21.
The inspected Google project is still Free Tier, unsuitable under Google’s unpaid
terms for BNYAD’s personal nutrition information. Keep AI off until the owner
arranges a suitable project and separately approves testing/activation.

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
Do not advertise production AI as restored. The app now rechecks server
availability before an AI upsell and explicitly explains on Premium that a
subscription does not enable paused AI. The same client can use later compatible
backend activation without another store submission. See backend
`vercel-api/GEMINI_PRODUCTION_ACTIVATION.md`.

Before authorized activation, configure server-only variables from
`AI_RELEASE_HANDOFF.md`: `GEMINI_API_KEY`, `GEMINI_MODEL`, `AI_ENABLED`,
`AI_MONTHLY_BUDGET_USD`, token prices and per-user/rate/output limits. Use the
documented supported `gemini-3.5-flash-lite` only after project access and quota
are checked under a new authorization. Never put the key in Flutter.

## Push: confirmed causes and changes

Production's `FIREBASE_SERVICE_ACCOUNT_JSON` was scoped to Preview only, so the
production server had no configured Firebase credential. Its existing value has
now been scoped to both Preview and Production without reading or exposing the
secret. The repaired Production deployment now includes that scope change. The owner
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

The owner selected a single account they control for production push tests; no
broadcast was sent. First test: one Firebase acceptance, zero failures; the owner
reported alerts/tap-open on both phones, but the provider count establishes only
one registered recipient and does not independently prove two-device delivery.
Second, uniquely labeled `BNYAD LOCK-02`: one acceptance, zero failures; the owner
specifically confirmed it appeared on the **locked iPhone** and opened BNYAD.
Foreground/normal-closed state coverage and an unambiguous Samsung test remain.
These tests used the existing published apps, so they do not prove every new
Flutter client-registration path in the unreleased binary. Local Dev intentionally
disables production Firebase; its working dashboard is not a push-delivery test.
Force-stopped OS states do not carry a delivery guarantee.

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

The owner signed into App Store Connect and reported resolving the updated Paid
Applications agreement. The last observed iOS live version was 1.0.1, build 13.
The production 1.0.2+14 archive and IPA export succeeded using Cloud Managed
Apple Distribution and the existing team store profile. Exported bundle identity,
HealthKit, production APNs entitlement, strict signature verification and disabled
debug entitlement passed. Both final binaries were rebuilt with the AI-availability notice and signed
validation passed. Artifact SHA-256 values and source commits are recorded in
`RELEASE_CANDIDATE_1.0.2_14.json`; artifacts remain local and are not committed. Latest editable store version/build checks,
upload, review and release remain outstanding. Do not treat a development installation
as an App Store release.

## Tests and dependency changes

- Flutter: analysis has no issues; all 378 tests pass after the critical fixes.
- Backend: 136 tests pass; TypeScript passes; Next.js production build passes.
- Next.js patched to 15.5.28, including its matching lockfile packages, for
  GHSA-2464-fhr4-w9xw / GHSA-p3m5-59mp-jv5r. Production npm audit: zero advisories.
- Real isolated local PostgreSQL integration passed auth, Premium, consent,
  all four mock AI operations, multilingual output, quotas and persistence.
  This did not call Google or use production customer data.
- Local preview uses separate build output directories so it cannot overwrite
  the running local iPhone backend's Next output.
- HealthKit/Health Connect reading logic, nutrition targets and the walking-calorie
  formula are preserved. Android adds only a debug-local-backend authorization
  method; it does not alter step queries or grant production access.

## Barcode, Camera Permissions & Android Distribution

### Confirmed causes and repairs

- The iOS permission-handler Camera implementation lacked its required CocoaPods
  `PERMISSION_CAMERA=1` compile flag. This can return denied without a native
  prompt, even when Info.plist usage descriptions exist. The flag is now verified
  in all six generated configurations. Shared permission handling distinguishes
  first request, granted, denied and restricted access, with localized Settings
  guidance. No microphone or photo-library permission is newly requested.
- `mobile_scanner` is updated from 6.0.11 to 7.4.2: maintained native Android
  CameraX/ML Kit and iOS AVFoundation/Apple Vision integration, tap focus, frame,
  torch state, bounded duplicate handling and manual entry. Detection and food
  lookup do not require Gemini.
- Previous client-side product guessing is replaced with authenticated exact-GTIN
  backend lookup. Checksums, leading zeros, UPC-E expansion and exact GS1 (01)
  are validated. Open Food Facts is first; USDA branded-food exact matches are an
  optional server-key fallback. Incomplete or inconsistent label values are
  rejected; a similar product name never supplies nutrition automatically.
- Public label cache is separate from private logs/catalog: seven-day positive
  and one-hour negative cache; outages are not negatively cached. Shared database
  provider limits are conservative (OFF 7/minute, USDA 8/minute), with per-user
  20/minute limits and no provider retries. A fixed-window boundary can double a
  burst, so the provider ceilings deliberately leave headroom. Cache expiration
  cleanup is bounded. See backend `BARCODE_DATA_SOURCES.md` for licensing and
  configuration limitations.
- Label basis, quantities and logs now distinguish grams from milliliters.
  Liters normalize only to milliliters; no density or 1L=1kg assumption. Verified
  serving sizes scale every macro consistently. Ambiguous OFF label metadata
  requires explicit label-basis confirmation; product/label values can be
  corrected before logging. Manual and catalog fallback remain available.
- Settings displays the actual installed version/build, avoiding hardcoded text.

### Evidence and actual coverage

Google Play production is versionCode 8 (1.0.0), fully rolled out across 178/178
regions. The purported newer code 13 (1.0.1) is **still a draft**, not a published
update. The connected Samsung SM-G990B2 has Play-installed `com.bnyad.app` code 8,
matching production exactly. This establishes the cause for this phone; it does
not prove the state of every other Android model. The existing draft is preserved.
Country-specific eligibility, managed publishing and device exclusions still need
final console verification. Candidate code 14 is higher than the last observed
uploaded code 13; recheck before upload.

The complete authenticated local-backend Samsung Dev app `com.bnyad.app.dev`
1.0.2+14 was installed and launched separately. The owner confirmed login and
barcode scanning work. It uses fictional QA data, real Health Connect and simulated
AI; no production app/data was replaced and no Google request was made. The
Android entry point and application suffix are guarded to debug only; release
and profile builds cannot enable this diagnostic configuration.

Real local HTTPS/backend integration passed normal login, unauthenticated 401,
OFF lookup and repeat cache hits for Coca-Cola Original, Nutella and an existing
SKYR product. An apparently random valid barcode was an actual OFF record, so it
was not misreported as a missing-product test. Missing-product behavior, malformed
responses, exact identity, UPC/EAN, dense liquids and unit arithmetic are covered
by mocks. USDA is mocked only because no server key is configured. No claim is
made of universal Iraq/Kurdistan product coverage or verified crowd-sourced labels.
A fictional 250mL milk log persisted with its unit, then was removed normally;
food targets and the cumulative Gemini ledger remained unchanged.

Flutter includes 18 confirmation-layout cases (English, Arabic, Sorani; 320/390/430
widths; light/dark), plus localized 0.25L logging and duplicate-save tests. All
378 Flutter tests pass. Camera authorization states and native-local-build guards
have automated coverage. The latest complete iPhone Dev upgrade was installed and launched successfully.
The owner confirmed barcode, food-photo and fridge-photo cameras all open, with
real steps/calories and the saved goal preserved after reopening. A clean camera
permission-state test, physical solid/liquid entry, Samsung step/persistence
regression for this specific build and visible push on both platforms remain
release gates. Successful
mock AI screens do not establish real image recognition.

## Required rollout gates

1. Production Neon mapping and recovery branch are verified as recorded above.
   Inspect the selected main branch/database immediately before any SQL operation.
2. Review/apply, in order, only these additive migrations to that verified target:
   `db/20261013_auth_rate_limits.sql`, `db/20261013_ai_safeguards.sql`,
   `prisma/notification_translations.sql`, `db/20261025_push_delivery.sql`,
   `db/20261025_barcode_units.sql`.
   All have been tested on isolated local PostgreSQL;
   **applied and schema-verified on 26 October 2026**.
3. Verify the existing Firebase service-account project and permissions, and the
   RevenueCat V1 secret/entitlement mapping. Never replace live store entitlements
   or grant client-claimed Premium as a shortcut.
4. Deploy the tested backend branch to the existing `nutrify-api` project with
   root `vercel-api`; check readiness, admin auth and existing-client compatibility
   after deployment. Keep AI off as approved for this release.
5. Verify actual push delivery on both phones, purchase/restore compatibility and
   existing account/session behavior. Then create only the necessary store
   binaries, tied to the final source commits and checked private configuration.
6. Obtain owner Apple sign-in/signing approval as necessary. Update store metadata,
   submit tested binaries, and report each store's actual review/release status.

No billing was activated, no new paid resource purchased, no live Gemini request
made and no mobile release submitted. Production changes consist of the approved
additive schema, backend deployment, configuration and two owner-targeted test
notification records. Customer nutrition/subscription values were not rewritten.
New auth may migrate existing sessions to hashed storage during normal use.

## Internal TestFlight validation — 26 October

The owner explicitly approved internal-only TestFlight upload and temporary
replacement of their iPhone's App Store copy for no-charge sandbox testing.
No App Review submission or public release is authorized until remaining checks
pass. The existing Dev and Health Test apps must remain separate.

Build 1.0.2 (14) uploaded through Xcode with `testFlightInternalTestingOnly=true`,
but Apple rejected ingestion for missing `NSHealthUpdateUsageDescription`.
It is **not** available in TestFlight; the phone's installed production app was
still 1.0.1 (13). No replacement or deletion has occurred.

All five native plist configurations and English/Arabic/Sorani locales now include
an accurate health-update explanation: BNYAD does not request permission to add or
change Health data. The authorization code is unchanged (`toShare: []`). No
HealthKit entitlement was removed and no write permission added. Plist validation,
Flutter analysis and all **378 tests** pass, including privacy metadata/read-only
regressions. Build 15 is being prepared to avoid ambiguity with the rejected
upload. Its internal-only flag will prevent external TestFlight/App Store use;
a subsequent production-eligible iOS build is required after QA passes.

The owner confirmed their current Premium is an admin grant, not a store purchase;
it remains intact and does not count as purchase/restore verification. Basic
TestFlight purchases use Apple's sandbox without real payment; do not purchase
through the published app or sign out of the owner's main Apple Account merely
to perform the basic test. Separate sandbox controls may require further setup.

Play Console additionally confirms Iraq is Targeted and managed publishing is
off. Production is code 8 at 100%; code 13 remains an unmodified draft, and
Create new release is disabled while that draft exists. Do not silently discard
or replace another developer's draft to upload the new candidate.

## Internal TestFlight result — build 15

Corrected iOS source `3680f05c7451753f7eb963b7d4acf7ae59016b5f` built and signed
successfully as 1.0.2 (15). Xcode reported Upload succeeded, and App Store Connect
Build Uploads reports Complete, build ID `675e0540-dc61-4901-98dc-c3c542366830`.
The owner completed Apple's encryption declaration in the browser; the missing
compliance prompt is gone. No legal declaration was selected/submitted by the
agent. Internal testing remains restricted by the upload flag; this build cannot
be used for an external/public release.

The owner explicitly approved preserving automatic distribution to the existing
five-member internal group `ahmed test`; no group/tester was deleted or changed.
Although the build page initially displayed Groups (0) and manual group selection
was disabled, the owner obtained it in TestFlight. A fresh device query confirms
installed production bundle `com.nutrify.bnyad` is now **1.0.2 (15)**, and launch
succeeded. The temporary replacement was specifically approved; no uninstall was
performed. BNYAD Dev remains separate. The owner confirms dashboard, first-use
native Camera prompt, barcode camera, both store prices and AI-disabled notice.
AI photo/fridge capture is intentionally gated by the disabled service; real
recognition is not being claimed. Their capture flow was exercised previously
in the isolated simulated-AI Dev build.

The existing account's admin Premium grant is preserved and is not store-purchase
proof. A separate free fictional QA account was created through the normal admin
flow with a password entered privately by the owner. The owner completed a
no-charge TestFlight sandbox purchase. Fresh admin evidence confirms Premium
with plan `store_verified`; Restore succeeds and access survives restart.
An earlier Free/new UI result was stale, not evidence of verification failure.
No real-money purchase or new Gemini call occurred. Public App Store/
Play submission and release remain paused for the remaining regression gates.

## Purchase verification hardening — 26 October

The SDK previously set cached Premium immediately, then posted backend
verification without waiting. Although the supervised sandbox purchase did reach
the backend successfully, that ordering could falsely report success during a
verification outage. Purchase/restore now await authenticated verification and a
trusted server access snapshot. Stale session results are discarded, requests
have bounded timeouts, and existing grants are preserved during temporary
verification failure. English/Arabic/Sorani messages explain pending verification
and advise Restore without purchasing again. Settings restore messages also use
the existing localization layer. Nutrition, HealthKit and subscription records
are unchanged. Flutter analysis and all 390 tests pass; backend 136 tests pass.
The added 12 tests cover awaited verification, 403/503, server denial, expiry,
manual-grant preservation, logout at each async boundary and localized messages.
The change is not yet installed in a new TestFlight binary.

Global Premium Gifts is newly requested and under implementation. No campaign
has been created or executed against production. Public mobile release remains
paused until the expanded requirements pass.

## Global Premium Gifts — implementation and isolated verification

Added server-authoritative promotional credit support to the full mobile app,
without altering billing, nutrition targets, activity formulas or native health
permissions. Gifts have localized details, FIFO/paid-pause explanations, dates and
remaining credit. Store management is shown only for store-managed access.
Foreground push/resume/polling refreshes access; account switches clear gift
metadata. Campaign history does not replay its push alert as a second local alert.

The backend implementation is in the official backend repository: durable
Workflow, fixed recipient snapshots, explicit confirmation, 25-recipient/device
batches, transactional idempotency, separate notification outbox, cancellation,
per-recipient unused-credit remediation, history and audit. Lifetime credits are
banked; paid renewals defer unused gift duration. Five additive tables are
prepared, with the feature disabled unless explicitly configured.

Isolated PostgreSQL tests passed for 10,000 fictional recipients, duplicate and
concurrent execution, forced transaction failure/retry, paid/lifetime/overlapping
credits, missing/invalid devices, safe push retry, cancellation and remediation.
A separate five-user local HTTP/durable-worker flow and browser confirmation flow
completed correctly. Admin layouts were inspected at desktop, 768 and 320px.
Flutter analysis and 410 tests pass; backend 151 tests, types and production build
pass; patched dependency audit reports zero vulnerabilities. No production gift,
broadcast or new Google request was made.

Release candidate is now 1.0.2 (16). This is source/build preparation, not a claim
that build 16 has been uploaded or installed. Backend activation, physical gift
verification and store release gates remain outstanding. See
`PREMIUM_GIFTS_HANDOFF.md` and backend `PREMIUM_GIFT_CAMPAIGNS.md`.


## Gift rollout and signed candidate verification — 26 October

Backend source `1e9e577e8acff94cd248fe25f6714a8ae4f81aad` is now deployed:
https://nutrify-dxa3lx2ui-ahmads-projects-67e04419.vercel.app
(`dpl_3h4qG97wYbZ6EHxVUL8MnYdRJL78`), serving the existing production alias.
Public readiness returned 200 with that exact revision. Gift/subscription/admin
endpoints return 401 without authentication; local/staging readiness remains 404.
No error/fatal runtime logs were returned for this deployment during the initial
post-deploy check; this is a bounded observation, not a guarantee of future uptime.

The five gift tables were applied to the previously identified Neon main/neondb
in an explicit transaction with 3-second lock and 30-second statement timeouts,
a database-name guard and a precondition that no gift tables already existed.
The preflight showed neondb/neondb_owner and zero existing gift tables. COMMIT
succeeded, followed by a production campaign count of zero. System environment
variables are enabled for the managed Workflow build/runtime, and Production
`PREMIUM_GIFTS_ENABLED=true` is configured. The authenticated production admin
loads Global Premium Gifts, multilingual previews and empty campaign history.
No campaign was created, confirmed or executed in production. Cloud-worker
execution is intentionally untested against production recipients; local durable
execution passed. Repaired backend `0b0726f...` remains the rollback baseline;
leave additive tables in place and never restore old customer data routinely.

Main application source for candidate 16:
`53a23c0f7baf3ea4396f0e84e7183ae54eaaa00b`.
Android release AAB 1.0.2 (16) built, passed bundletool validation and jarsigner
verification, and matches the existing Play upload certificate documented above.
AAB SHA-256: `4225475e6c0a6c502c1892f65c27ed70cb730023ed06f4328b7744ba27e8c0c8`.
iOS archive 16 built with the production bundle identifier and HealthKit. Its
store export/upload is separate from the development-signed archive; verify the
exported production APNs entitlement before claiming a store-ready artifact.

Separate BNYAD Dev 1.0.2 (16) was installed/launched on the connected iPhone,
using the dedicated authenticated local PostgreSQL/HTTPS backend. A guarded local
fixture gave only its one fictional QA account a seven-day credit using the real
server entitlement transactions. Subscription rows and the 21/21 Gemini ledger
were verified unchanged; no FCM send was attempted. The owner confirmed gift
details/dates/remaining credit, readable Kurdish layout, and steps/saved-goal
persistence after reopening. This is real native display against fictional local
data, not a production grant or production push test. Samsung is not currently
detected, so the new gift feature is not yet physically verified there.

Hosting gate discovered through the authenticated Vercel account context:
the existing team is on Hobby. Vercel limits Hobby to non-commercial personal use;
BNYAD sells subscriptions. Owner review of a commercial hosting plan or explicit
Vercel arrangement is required before expanding public production use. No billing,
trial or paid overages were enabled. See https://vercel.com/docs/plans/hobby and
https://vercel.com/docs/limits/fair-use-guidelines . Confirm remaining Workflow
allowance before the first real campaign; no production campaign was used to
consume or test that allowance.

Public releases remain pending: new TestFlight candidate processing/regression,
Android device regression, existing Play draft 13 handling, store metadata/privacy
review and outstanding push-state coverage. The previous Play draft is preserved.
AI stays disabled for everyone and Google request count stays 21/21.


Apple upload of 1.0.2 (16) completed successfully through Xcode on 26 October.
The upload omitted the internal-only restriction so the tested candidate can be
used for a later authorized store submission. Upload is not App Review submission,
processing approval, a TestFlight installation or public release. The existing
five-person internal group configuration was preserved.

## Store candidate checks and Android permission repair

Apple processed release-eligible build 16 (build ID
`165908c3-c46e-45ab-a79e-d8d62803f69f`). The owner personally saved export
compliance. The existing internal group automatically received the build, and the
owner confirmed dashboard, barcode camera, real steps/saved goal and Premium/
Restore with the AI-disabled notice. The App Store 1.0.2 draft now selects build
16; name `BNYAD: Calorie & Macro Tracker`, subtitle, Health & Fitness category and
accurate AI-disabled English description/release notes were saved. No App Review
submission is implied by those draft changes.

The exported IPA was independently signature-verified: production APNs,
HealthKit enabled, get-task-allow false, existing production bundle ID, version 16.
IPA SHA-256: `b72cf2dbf10832eaa7ea0af52162591dcb31dca35bc1c29dceba5b1b972068c2`.

After the owner accepted Google's Device Catalog agreement personally, inspection
showed 19,420 supported models and zero excluded models/rule exclusions. Both
S21 FE variants are supported. Play's build-16 review showed no lost supported
phone/tablet models versus code 8, but blocked submission on existing broad-photo
and restricted exact-alarm declarations. The Android manifest unnecessarily
requested READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE and USE_EXACT_ALARM.

Android code 17 removes those permissions. The existing image_picker system
picker/GET_CONTENT grant supplies selected images without broad library access.
CAMERA remains. SCHEDULE_EXACT_ALARM and its existing user-approval flow remain
for optional meal reminders, rather than claiming alarm-clock/calendar core use.
No notification scheduling code, iOS code, health permission or nutrition logic
was changed. Android's platform-only repair does not replace the tested iOS 16.
Primary guidance: https://support.google.com/googleplay/android-developer/answer/16558241 ,
https://pub.dev/packages/image_picker and
https://developer.android.com/reference/android/Manifest.permission#SCHEDULE_EXACT_ALARM .

Flutter analysis and all 410 tests passed again. Signed AAB 17 passed bundletool,
jarsigner and existing upload-certificate checks. An automated check of its actual
bundle manifest confirmed code 17, com.bnyad.app, absence of broad photo/storage
and USE_EXACT_ALARM, with camera, SCHEDULE_EXACT_ALARM, notifications and Health
steps preserved. AAB SHA-256:
`43ec1de05298df695bca17d292ac65d47d5c85009f3c2a0c9a267c75c11abac2`.
Samsung is unavailable; no new physical Android result is claimed.

The owner approved replacing the unpublished Play draft while preserving notes.
Code 16 was uploaded and saved in that draft; original code-13 notes were backed
up privately. Code 17 is the corrected candidate for re-upload. Google Play's
English name and accurate description were saved as a listing draft. Final
validation/review submission still needs verification.

The owner chose to defer the Vercel paid-plan purchase until 29 October but
explicitly requested submission of tested store updates today. Checkout was
cancelled without payment; Hobby and the existing backend remain unchanged. The
commercial-hosting policy issue was disclosed, not technically resolved. No plan,
trial, paid overages or Gemini billing was activated. Store review timing remains
controlled by Apple/Google; no same-day public availability is promised.

## Verified store submissions — 26 October 2026

Read-only recheck after the owner's final submissions:

- Apple submission `632812ba-6cb7-4b74-a4ca-4dc6c55f5d75` shows **Waiting for Review**, submitted 26 October at 4:29 PM as displayed in App Store Connect. iOS 1.0.2 uses verified build 16, source `53a23c0f7baf3ea4396f0e84e7183ae54eaaa00b`. The new name/category and accurate AI-disabled metadata were saved before submission.
- Google Play submission **9** shows **In review**, submitted 26 October at 4:28 PM as displayed in Play Console. Its exact contents are Production **17 (1.0.2)** full rollout plus English default-listing name, short description and full description. The name is **BNYAD: Calorie & Macro Tracker**. Android source: `84d27c5860596de257d43921e9b5a68c844bdd6c`. The two permission validation errors cleared before submission; no supported phone/tablet models were lost versus code 8.
- Neither review status means approved or publicly live. No submission was cancelled or duplicated during this verification.
- Backend deployment remains `1e9e577e8acff94cd248fe25f6714a8ae4f81aad`; backend GitHub head `06bc00f43f3815da60699c69759145785ddb9ba5` adds local QA helpers/documentation only. AI stays off; Google request ledger is 21/21. No production campaign, hosting purchase or AI billing activation occurred.
