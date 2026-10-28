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

On the connected iPhone, the isolated Profile-dev harness installed and launched successfully. Its native bridge recorded `startup_smoke_native_store_unconfigured` and then `startup_smoke_pass` after the restored fictional account/dashboard and resume checks. This uses the real iOS RevenueCat configuration query, not a mocked purchase SDK. No new crash report appeared during these checks. It does not claim a new production-account purchase/restore, Gemini or HealthKit-data test. The owner separately confirmed Android is working; no Android device was connected for an additional physical smoke test.

Both signed production artifacts were also inspected directly: their appropriate existing PUBLIC RevenueCat key is present in the compiled app (values were not printed). iOS retains production push and HealthKit entitlements, with `get-task-allow=false`; distribution signature verified. Android retains package `com.bnyad.app`, existing upload certificate SHA-256 `5B:0F:D7:E9:83:16:75:5E:C1:35:97:BE:A5:34:F7:57:52:AD:46:28:6A:40:7F:0A:B0:97:86:E0:99:CC:57:5B`, and its JAR signature verifies.

- iOS IPA SHA-256: `7d3533d411eb8d4c8498af54e7d57b0469f03b82dc9e7d49fc32787bd5e1d281`.
- Android AAB SHA-256: `26ed1ee2a25327d0176ef8ccc9dd1953fee35debf01fd8b4e3140fae5af862e2`.

Apple completed processing; the owner personally saved the required export declaration. iOS 1.0.4 (19) was submitted on 28 October 2026 at 3:07 PM (Apple display time). Submission `380ee937-1393-43dd-9caa-d27508911dd5` shows **Waiting for Review**; Apple build ID `a0d023c0-584c-4f95-9a88-4f1ff292f090`. Existing automatic release after approval is preserved.

Google Play production 19 (1.0.4) was submitted with the existing full rollout settings and maintenance notes. Its console shows **Changes in review**. Neither submission status is a claim that the hotfix is already approved or available publicly.

Runtime source fix: `93775fe` on `codex/bnyad-production-repair-2026-10-25`. The following documentation/native-harness update does not alter the uploaded production runtime. Backend source and deployment remain unchanged. The isolated native harness is `test/device/startup_smoke.dart`; it is limited to the offline development bundle, uses fictional in-memory account/storage/HTTP fixtures, does not call Gemini or production APIs, and cannot be built as a store entry point. It deliberately leaves the real native subscription SDK unconfigured to exercise the reported failure path.

No backend change, migration, billing change or live Gemini test request is needed. The prior development request ledger remains unchanged.
