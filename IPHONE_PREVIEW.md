# Complete BNYAD iPhone development preview

This installs the existing complete Flutter `BnyadApp`, not `HealthTestApp`.
No verified staging URL/environment identity was configured locally when this
preview was prepared. Production was not contacted, redeployed or modified.
Normal production and staging entry points are unchanged and do not import
the offline preview or its authentication fixtures.

## Safe mode and feature boundaries

- App: **BNYAD Dev**, bundle **com.nutrify.bnyad.dev**. This is distinct from
  **com.nutrify.bnyad** (published app) and **com.nutrify.bnyad.healthtest**.
  Only the dev identifier is installed/updated; no uninstall command is used.
  Keep the original App Store and Health Test apps/data intact.
- `lib/main_iphone_preview.dart` reuses the complete existing app, screens,
  dashboard, navigation, food database/calculations and state management.
- Authentication/registration/OTP, nutrition profile, food/water/weight logs,
  saved daily meal plan and premium status use existing **fictional local API
  fixtures**. These are not server-verified accounts or subscriptions. Login
  UI can be opened from the local controls. No SMS or real purchase is made.
- `ApiService.aiEnabled=false`: Gemini, AI recipe generation, food/fridge photo
  analysis and meal regeneration are **unavailable**, not represented as live
  results. Existing daily-plan fixtures, planner UI and other screens remain
  available. No Gemini key, backend or new service is required.
- Barcode camera/decoder and bundled food lookup remain compiled/integrated.
  External barcode databases are blocked; products absent from local data need
  manual entry. Camera permissions, real barcode capture, photo picker, and
  every recipe/meal screen require further device QA; startup is not proof that
  all features have been tested.
- Apple Health uses **NativeStepHealthProvider**, the same Swift HealthKit
  statistics bridge as the diagnostic, never DemoStepHealthProvider. Steps
  require separate consent/OS permission for BNYAD Dev, independently of Health
  Test. Daily totals remain in memory; settings/accepted goal persist in the
  dev app's local keychain.
- Optional real body values for walking estimates are entered via **Local test
  controls · health profile → Health profile (device only)**. They are stored
  separately in the local keychain and never enter the nutrition fixture API,
  fictional weigh-in history, production profile or network requests. Until
  supplied, no calorie estimate is shown; fictional sample body data is never
  substituted. Profile/goal changes do not mutate nutrition targets.
- Walking calories never increase food allowance. Goals retain the original
  conservative starting suggestions, confirmed-history rules, explicit
  acceptance, manual override and cooldown. See STEP_TRACKING.md.

## Isolation safeguards

Native preview activation requires non-release iOS, native development
compilation, exact dev bundle ID and the `BNYADOfflinePreview=true` marker in
`Runner/OfflinePreview-Info.plist`. The native method-channel check must succeed
before constructing any fixture service. Release, production bundle, Web,
Android, missing marker or missing/false check fails closed.

The browser demo remains restricted to localhost debug Web; its simulated
step provider still rejects native use, including an authorized native preview.
Existing fixture services can run in profile mode **only** following the
explicit native handshake. No Dart define alone can enable this mode in a
normal release.

The fixture URL `bnyad-demo.invalid` is a virtual route namespace intercepted
by injected `MockClient`, **not a server the phone attempts to reach**. There
is no real DNS/socket transport for it. A native-preview-only `HttpOverrides`
also rejects accidental Dart HTTP client creation before network access.
External URL launching and barcode HTTP are intercepted. Optional billing,
push, notification initialization/scheduling and connectivity DNS probes are
disabled through an injected setting whose normal-app default stays enabled;
HealthKit is independent and remains enabled. The dev native configuration
already skips Firebase initialization/APNs registration.

Fictional sessions/nutrition caches use the separate `bnyad_iphone_preview.`
preferences namespace. Health profile uses a separate local, non-synchronizing
keychain key; health connection/goal settings retain account/environment scope.
Never use real production account details in the local login or onboarding UI.

## Build / install

```sh
FLUTTER_BIN=/absolute/path/to/flutter bash tool/run_iphone_preview.sh TEAM_ID DEVICE_UDID
```

The script gets dependencies, prepares the existing dev flavor, builds a
**profile-mode AOT development-signed app**, verifies its exact bundle/marker,
installs it directly on the specified trusted iPhone and launches it. Profile
mode permits reopening from the home screen without a JIT debugger. It never
archives, uploads, exports, purchases, deploys or submits to either store.
Signing credentials/profiles and team/device arguments are not committed.
Use an existing eligible Apple Developer team/certificate and HealthKit-enabled
development profile. HealthKit entitlements must not be removed to bypass
signing. CocoaPods dependencies are unchanged.

## Health refresh / reopening checks

1. Open **BNYAD Dev**, not Health Test. Expand local controls to set your own
   health-estimate profile; collapse controls to explore the complete app.
2. Tap the dashboard activity card → Connect → accept the explanation → allow
   Steps in Health. Walking + Running Distance is optional. This app has its own
   authorization; granting Health Test access does not grant BNYAD Dev access.
3. If data is empty, inspect **Local date being read** and Apple Health → Steps
   → **Today** on the same date. After midnight, yesterday's steps are not
   today's total. Missing/private data remains unknown, never an invented zero.
4. A saved connection now remains visibly **saved** even if today's reading is
   empty; the UI no longer suggests repeatedly connecting solely because data
   is empty. Review OS permissions in Health → profile → Apps and Services →
   BNYAD Dev; refresh after Health/Watch sources have synced.
5. Reproduced/fixed: a permission sheet could leave Flutter's foreground flag
   false, causing `connect()` to save consent but skip its final refresh while
   retaining an indefinite “Refreshing…” label. Forced reads can now confirm
   native UIKit foreground state (active or inactive, never background); if
   foreground cannot be confirmed, show an explicit waiting state instead of
   a false in-progress read. Resume refresh remains active. Actual reads still
   have the existing timeout and bounded daily queries. This is not background
   health collection or polling.
6. Choose a manual goal, close and reopen. Consent/goal should restore without
   requesting permission again; totals are reread from Health, not cached as
   fresh. Compare Health Today, walking-after-sync updates and estimates using
   your own values. Do not commit real health readings/screenshots to GitHub.

## Verification and remaining checks

### Empty current-day investigation

The offline development build now compares an empty current-day collection
result with one independent, read-only `HKStatisticsQuery` for the same window.
This extra query is compiled only with `BNYAD_DEVELOPMENT` and requires the
offline preview plist marker. It never replaces the displayed reading or alters
permissions. Diagnostics contain only readability/boundary flags and the error
code, not quantities, dates, samples, sources or profile information. Diagnostic
arguments are evaluated lazily so normal builds do not scan history for logs.

On the connected device, historical aggregates were readable, current-day bucket
boundaries matched, and the independent query confirmed the native current day
but returned `HKErrorDomain` code 11 (`errorNoData`). The owner reports Steps
permission is on and the separate Health Test also currently has no steps.
This establishes that the full app's UI is receiving an empty HealthKit result;
it does not yet explain the discrepancy with the owner's Health Today view.
Same-date Health chart comparison and walking/sync checks remain outstanding.
Do not claim a complete real-device fix or substitute zero/simulated steps.

Focused regression validation: 89 step/native-preview tests passed; Flutter
analysis clean. The updated native development app built, installed and launched.

Flutter analysis and full tests cover runtime guards, HTTP blocking, complete
app mounting/navigation/premium UI, local login/session/food/water persistence,
real-native-provider wiring using **mocked channel responses**, health profile
isolation, goal restoration, empty-today cold starts and permission-sheet
lifecycle recovery without background reads. Existing step algorithms and
nutrition targets are regression-tested. Narrow-screen Settings headings/CTA
and Premium price rows found during verification now wrap within their existing
layout; colors, styling, destinations and subscription rules are unchanged.

Native signing/build/install/process launch were checked on the connected
iPhone 15. The owner reached the activity screen and reported refresh/empty
issues. After the update, the owner's screenshot shows a saved connection and
a completed refresh with no readable data for the current local day; this is
not an in-flight/stuck query. Native device diagnostics also confirm the
HealthKit step and distance queries complete without errors, in both UIKit
inactive and active foreground states. Empty HealthKit results still cannot
distinguish no records from private/denied reads. A same-day Apple Health
comparison and fresh walking/goal/restart checks require owner confirmation;
do not claim these are fully verified. The owner reports the
separate Health Test icon remains present; no uninstall was performed.

Final automated checks: Flutter analysis clean; **231 tests passed**. Preview-only
diagnostics report connection/storage/read-stage/foreground metadata, never step
totals, distances, profile values, dates, account IDs, keys or tokens. The native
logs are gated to the offline dev plist; the normal tracker callback is null.
The yellow native-only status line identifies preview H3 and its current read
state for troubleshooting. Do not copy the owner's health screenshots to GitHub.

Existing native startup/build warnings include MLKit platform/simulator support,
Swift Package Manager/CocoaPods integration and duplicated Google utility
classes across current dependencies. The full app ran without an observed
startup crash; these dependency warnings still need release-developer review.

Real backend login/registration/OTP, server persistence, billing, push, external
barcode lookup and AI are **not tested end-to-end** in this offline preview.
Use `main_development.dart` with an independently verified compatible staging
environment for those server tests later; it still refuses missing/unverified
staging instead of silently falling back to production. No migration, new API
credential, backend change or deployment is part of this installation.
