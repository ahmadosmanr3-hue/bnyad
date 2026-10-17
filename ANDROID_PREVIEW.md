# Complete BNYAD Android development preview

`lib/main_android_preview.dart` reuses the existing complete offline app runner
from `main_iphone_preview.dart`. It mounts `BnyadApp`, all existing screens and
the original design. Account/nutrition data is fictional and local. Health
Connect readings are real; no native simulated step provider is imported.
Gemini, backend transport, SMS, billing and push startup remain disabled.

## Isolation

- Installed ID: **com.bnyad.app.dev**, label **BNYAD Dev**, debug signing only.
  Existing **com.bnyad.app** and its data are never updated or uninstalled.
- Explicit Gradle property `bnyadOfflinePreview=true` selects the separate debug
  manifest and application-ID suffix. Native authorization requires all of
  `BuildConfig.DEBUG`, `BNYAD_OFFLINE_PREVIEW` and the exact dev ID. Dart also
  rejects release/Web/unsupported platforms and a missing/false native guard.
  Ordinary build defaults and release signing remain unchanged. The special
  property rejects app Release/Profile packaging tasks.
- Preview manifest removes **INTERNET**, removes Firebase's auto-init provider,
  and disables messaging/analytics auto-init. Dart HTTP is separately blocked.
  Health Connect uses Android's local service and requires no backend.
- Fictional caches use `bnyad_android_preview.`. Your own estimate profile is
  separate, device-local secure storage, never the fictional account profile.
  Do not use a production login or enter real information into demo onboarding.
- Health permissions remain **READ_STEPS** and optional **READ_DISTANCE** only.
  No write, background-read, extended-history or sensor permission is added.
  Totals remain in memory, not logs/network/persistent storage. Existing native
  aggregate/source-priority, null-versus-zero and calendar behavior are reused.

## Build and install

Use an installed JDK 17 or 21 compatible with Gradle 8.14. Android Studio's
bundled Java 25 is incompatible. The script invokes Gradle with the supplied
`JAVA_HOME`, avoiding a global Flutter Java configuration change. The already
installed Android SDK/build-tools/dependencies are sufficient when available;
do not accept new license terms on the owner's behalf.

```sh
JAVA_HOME=/path/to/compatible/jdk/Contents/Home \
ANDROID_SDK_ROOT=/path/to/Android/sdk \
FLUTTER_BIN=/path/to/flutter/bin/flutter \
bash tool/run_android_preview.sh DEVICE_SERIAL
```

This ARM64 device script builds debug, verifies the APK has the dev ID and no
Internet permission, installs with data preservation and launches the complete
app. It never grants health permissions using ADB, resets app data, uninstalls,
signs a release or uploads anything. Build tools default to 36.0.0; override
`ANDROID_BUILD_TOOLS` if that installed SDK differs. No dependency upgrades or
new backend/API credentials are required.

## On-device verification

1. Unlock the Samsung and open **BNYAD Dev**. Confirm dashboard/navigation and
   the offline/real-health banner. No production account is needed.
2. Expand **Local test controls · health profile → Health profile (device only)**
   and save your own measurements. Without weight and height, the calorie line
   remains unknown; fictional body measurements are never used for real steps.
3. Open Daily activity → Connect → accept the in-app explanation → allow
   Health Connect **Steps**. Distance is optional. Grant consent yourself in the
   OS sheet; BNYAD has no silent grant or permission bypass.
4. Compare **today on the same local date**, not a weekly/monthly average.
   Health Connect must contain current-day steps. On compatible Android 16
   systems on-device step capture may be available; otherwise a source such as
   Samsung Health must sync/write Steps into Health Connect with your consent.
   Samsung Health's displayed total alone does not prove it has synced.
5. Carry the phone while walking, allow source sync, then Refresh (manual reads
   are throttled to 15 seconds). Missing data stays unknown. Do not insert fake
   steps or use the Health Connect Toolbox to fabricate native test records.
6. Choose a manual goal, close/reopen, and confirm connection/profile/goal
   persist. Totals are reread. Verify food calorie allowance stays unchanged.
   Recommendation testing requires seven reviewed complete historical days;
   a new connection may not yet have sufficient authorized history.
7. Revoke Steps in Health Connect and refresh: permission-unavailable UI should
   appear without blocking nutrition features. Re-enable only with your consent.

Relevant platform guidance:
- https://developer.android.com/health-and-fitness/health-connect/get-started
- https://developer.android.com/health-and-fitness/health-connect/features/steps
- https://developer.samsung.com/health/blog/en/accessing-samsung-health-data-through-health-connect

Automated fixtures validate wiring/guard/persistence/calculation behavior;
they do not validate OS permission sheets or real Samsung data. Record physical
device results separately and never commit personal measurements/screenshots.

## Recorded checks

- Starting remote commit: `c2852d939153298e374c99bdac0e7a37117d034b` on
  `codex/bnyad-stability-2026-10-13`, fetched and matched a clean local checkout.
- Samsung SM-G990B2 connected over USB, Android 16/API 36, SDK extension 23.
  Existing Health Connect system service is installed. The OS step-counter
  listener was active after Steps authorization; no sensor samples were logged.
- ARM64 debug APK built with the already installed JDK 21 and Android SDK 36.
  APK inspected for `com.bnyad.app.dev`, label `BNYAD Dev`, read-only health
  permissions and **absence of INTERNET**. App installed and process launched;
  owner confirmed the complete dashboard opens and granted Steps and Distance.
- The current native aggregate returned an empty reading without an error.
  This is not yet a verified real-step or calorie display. Same-day Health
  Connect data/source comparison and walking/profile/goal/restart checks are
  pending; no synthetic native steps were inserted.
- The original installed `com.bnyad.app` version and last-update timestamp were
  unchanged after dev installation. Ordinary debug manifest/config generation
  retained that original package/label/Internet access and preview flag=false.
  No normal build was installed. Preview release packaging was rejected in a
  dry-run before task execution.
- Flutter analysis clean; 244 tests passed, including both native-platform
  guard/mount checks with mocked Health responses, goal/profile restoration,
  nutrition isolation and HTTP blocking. Script syntax and whitespace checks
  passed. No dependencies upgraded, backend changes, deployments or purchases.
- SDK command-line tools are not installed and Flutter doctor cannot confirm
  licenses globally, but installed build tools/licenses sufficed for this build.
  Existing Gradle/AGP/Kotlin future-support, old plugin Java target and Android
  SDK XML warnings remain. The offline debug build cannot expose the Dart VM
  service without Internet permission; its socket warning is expected and does
  not prevent the dashboard/Health Connect from operating.
