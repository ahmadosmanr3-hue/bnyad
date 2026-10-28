# BNYAD startup crash hotfix — 1.0.4 (19)

## Confirmed cause

An owner-authorized iPhone crash report for the production bundle `com.nutrify.bnyad`, version 1.0.3/build 18, reports `EXC_BREAKPOINT` / `SIGTRAP`. Its Runner UUID matches the saved build-18 dSYM. Symbolication resolves the fault to RevenueCat hybrid `CommonFunctionality.customerInfo`, called from `PurchasesFlutterPlugin.getCustomerInfoWithResult`. The SDK terminates natively if its shared instance is accessed before configuration; Dart try/catch cannot recover from that fatal error. Raw device reports remain private outside Git.

Build 18 was made without the existing ignored `release-config.json`, so its public subscription SDK keys were empty. The startup sequence also allowed restored-session work to request customer information before asynchronous SDK initialization finished. This is a release-preparation failure, not an invalid user account or a Gemini/backend failure.

## Repair

- Share one guarded SDK initialization and await readiness before every instance operation: restored-session sync, login, products/prices, purchase, restore and logout. Missing/unavailable SDK configuration safely leaves store operations unavailable; it does not terminate the app.
- Preserve normal server-side entitlement verification. SDK success alone still cannot grant Premium.
- Execute a common release preflight from both Xcode and Android Gradle. It rejects missing/wrong-platform public SDK keys, unexpected store bundles/entry points, an unapproved API URL and known server-secret configuration names. It logs no configuration values. Existing development diagnostics remain isolated from production.
- Build store artifacts with `--dart-define-from-file=release-config.json`. The existing private file contains only production API URL and PUBLIC mobile subscription SDK keys; it remains ignored. Signing credentials and Gemini keys stay outside Git.
- Fix the dashboard date label's natural wrapping on very narrow Sorani screens, discovered by the date-dependent 280-pixel regression tests. Original typography, colors and calculations are preserved.

## Automated checks

`flutter analyze`: no issues. `flutter test`: 432 passed. This includes a real AppState restored-session/dashboard/resume test with an unconfigured mocked store, configuration concurrency/failure tests, both platform preflights, existing backend-verified purchase/restore tests, localization, steps and nutrition checks. A direct missing-key preflight also exits unsuccessfully with a sanitized message, as intended.

## Physical and store verification

Physical native-SDK regression, signed artifact validation and store delivery will be recorded after they actually complete. The isolated native harness is `test/device/startup_smoke.dart`; it is limited to the offline development bundle, uses fictional in-memory account/storage/HTTP fixtures, does not call Gemini or production APIs, and cannot be built as a store entry point. It deliberately leaves the real native subscription SDK unconfigured to exercise the reported failure path.

No backend change, migration, billing change or live Gemini test request is needed. The prior development request ledger remains unchanged.
