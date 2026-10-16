# BNYAD on-device step tracking — developer handoff

No backend endpoints, migrations, Gemini configuration, paid APIs or new environment variables are required. Nothing in this feature uploads health records. No deployment or store submission was performed.

## Implementation

- `lib/activity/step_models.dart`: calendar-day boundaries, conservative goals and walking estimates (pure Dart).
- `step_health_provider.dart`: bounded, validated method-channel contract. Web/desktop cannot read health data.
- `step_tracker.dart`: per-account connection/preferences, foreground refresh, midnight timer, correction replacement, stale-account and clock-change guards. No periodic polling or background collection.
- `step_widgets.dart` / `step_strings.dart`: original-style compact widget inside the existing calorie section, details/settings, English/Arabic/Sorani including RTL, full explanation before system permission requests.
- `ios/Runner/AppDelegate.swift`: read-only HealthKit daily statistics collection queries. Native merging, no raw source summation, local-calendar buckets, two one-shot queries per refresh (steps and optional walking/running distance).
- `android/.../HealthStepBridge.kt`: Health Connect aggregate API, no data-origin filter, no raw record summation. One bounded aggregate per day for today plus 14 completed days. Optional distance is omitted if denied.
- Only the isolated `main_demo.dart` imports `demo_steps.dart`. Its provider enforces localhost + debug + web at construction and at every call. Production/profile/release builds cannot enable simulated health data through a flag.

## Permission and privacy behavior

Steps are required for the feature; distance can be denied independently. Denying either permission does not block nutrition tracking or the application. No location, activity-recognition, health write, background-health, clinical-record, heart-rate or extended-history permissions were added. Android's normal 30-day history window is sufficient for a 14-day baseline.

Apple deliberately does not reveal read permission denial. A successful permission-sheet completion is NOT treated as proof of granted access. Missing/denied/limited-history HealthKit results stay unknown, not zero; the UI tells the user to check Health. Android can report denied/revoked access explicitly. Read failures clear current totals rather than presenting stale values as fresh.

Health totals, distance and calorie estimates exist only in memory and are refetched after restarting. Persisted settings include connection opt-in, manual goal, recommendation toggle, last accepted change and user-confirmed date identifiers. Mobile settings use local secure storage; iOS uses a non-synchronizable `first_unlock_this_device` keychain item. Android already has backup disabled. Web saves only settings in the existing isolated demo namespace; never native health records. Keys include backend URL and account ID so staging/production accounts do not share settings. Logout clears memory; deleting an account removes its step settings. Guests are local-only and their settings are erased on guest sign-out.

System health permission is app/device-wide, not BNYAD-account-wide. Each account requires its own explicit BNYAD connection consent. Users are warned to connect only their own health data, especially on shared devices. Disconnect stops reads and clears memory for the current account; it does not pretend to revoke OS access. Revoke access in Health/Health Connect using the instructions on the details screen. If secure storage cannot save a disconnect, BNYAD attempts to remove the stored opt-in; if storage is entirely unavailable, revoke OS permission as well before restarting.

No health totals/records are included in API requests, AI prompts, analytics, logs, push messages or food/nutrition calculations. Existing profile information already held by BNYAD is used locally for the estimate; no additional HealthKit weight/body data is requested.

## Goal algorithm and safety review

These are adjustable product defaults, not medical advice or clinically validated targets:

- Initial goals by existing onboarding activity key: sedentary 3,000; lightly active 4,000; moderately active 5,000; very active 6,000; extra active 6,500.
- A cautious 1,000 starting point and no automatic increases for profiles reporting any disability, age under 18 or 65+, pregnancy or breastfeeding. The user can choose a comfortable manual goal as low as one step; no walking target is represented as mandatory or appropriate for every condition.
- Health aggregates cannot prove a device was worn/carried for the complete day. Users must review and explicitly select representative completed tracking days, excluding incomplete/sync-pending, unusual, travel and timezone-change days.
- Require at least seven unique confirmed days from the preceding 14 calendar days; never use today, future/old days, missing counts or invalid totals. A real reported zero can be included only if the user confirms that day. Missing records never become zero.
- Use the median of eligible days × 1.05 as the candidate. Limit movement from the accepted goal to the smaller of 5% or 500 steps, rounding the permitted movement down to 50-step increments. At most one accepted recommendation every seven elapsed days.
- Automatic candidates stay within 1,000–10,000. Goals manually outside that range remain allowed, but adaptive changes are paused rather than violating either range or gradual-change limits.
- **Every goal change requires acceptance**, even a small one. Sync/corrections can update a suggestion, never the accepted goal. Confirmations for an obsolete suggestion are rejected. Manual edits pause recommendations; restoring recommendations does not reset the accepted goal.
- Timezone-offset/name changes invalidate confirmed history until reviewed again. Daily windows are recomputed on resume, local midnight and native significant-time/date/timezone notifications. DST uses calendar arithmetic, never repeated 24-hour subtraction.

## Walking calorie method

`estimated_kcal = floor(weight_kg × conservative_distance_km × 0.45)`.

Weight comes from the newest valid weigh-in already held in the current account's local history, falling back to its onboarding profile. Future/corrupt weigh-ins are ignored. No profile or nutrition goal is mutated.

Fallback distance is `steps × clamp(height_m × 0.40, 0.30, 0.75)` meters. If a finite, nonnegative native distance is available, use the **smaller** of that and the fallback. HealthKit's distance can include running and Android distance can include other activity, so it never increases the estimate. Denied/missing distance simply uses steps. Implausible/missing weight, height or steps produce no estimate, not invented personal data.

The level-walking ACSM horizontal term is 0.1 ml O2/kg/m (about 0.5 kcal/kg/km at 5 kcal/L); BNYAD uses a further 10% conservative discount, 0.45. The height-based stride and discount are explicit product assumptions, not validated measurements. No speed, incline, gait, carried load or exercise intensity is known. All steps are illustratively treated as walking; actual expenditure can differ substantially, especially for running, disability and atypical gait. The app prominently labels the result as estimated and explains the assumptions.

Walking calories **never** increase food allowance, subtract consumed calories, alter macro goals, or change TDEE. This prevents crediting activity already represented in onboarding activity/TDEE factors.

References checked during implementation:

- [Apple: HealthKit statistics merge sources by default](https://developer.apple.com/documentation/healthkit/hkstatistics)
- [Apple: daily statistics collection queries](https://developer.apple.com/documentation/healthkit/executing-statistics-collection-queries)
- [Apple: read authorization privacy](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [Apple: protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy)
- [Android: aggregated data and source priority/deduplication](https://developer.android.com/health-and-fitness/health-connect/aggregate-data)
- [Android: setup and required permissions rationale](https://developer.android.com/health-and-fitness/health-connect/get-started)
- [Android: platform compatibility](https://developer.android.com/health-and-fitness/health-connect/architecture)
- [AndroidX Health Connect release notes](https://developer.android.com/jetpack/androidx/releases/health-connect)
- [Google Play health app requirements](https://developer.android.com/health-and-fitness/health-connect/publish)
- [Level-walking energy equations and limitations, Journal of Applied Physiology](https://journals.physiology.org/doi/abs/10.1152/japplphysiol.00864.2015)

## Required developer/owner actions before release

### iOS

1. Use the existing Apple Developer Program team with HealthKit capability support. Do not purchase or change membership automatically. The former free Personal Team signing setup may not provision HealthKit; use the release developer's eligible team for device QA.
2. Open `ios/Runner.xcworkspace`, Runner → Signing & Capabilities. HealthKit is already declared in source for both normal and development entitlements. Do not enable Clinical Health Records or HealthKit background delivery.
3. Enable HealthKit for the actual app identifiers in the Apple developer account and regenerate/refresh development and distribution profiles. Preserve the production bundle identifier; the existing separate development identifier remains `com.nutrify.bnyad.dev`. No signing identities/certificates/secrets are in this change.
4. `NSHealthShareUsageDescription` is present in both plist configurations, with English, Arabic and Sorani localized strings. No `NSHealthUpdateUsageDescription` is needed because there are no write requests.
5. Update the published privacy policy and review App Store privacy disclosures against actual on-device-only processing and existing SDK behavior. No health records are stored in iCloud. The implementation does not change existing unrelated SDK disclosures.
6. Build/sign the dev flavor using a **verified staging** API and fictional test account; never use a production account/database for test writes. `main_development.dart` still refuses missing/unverified staging and keeps Gemini disabled.

### Android

1. New stable Maven dependencies: `androidx.health.connect:connect-client:1.1.0`, `androidx.lifecycle:lifecycle-runtime-ktx:2.8.7`. No new Flutter package or backend dependency.
2. Manifest declares only health `READ_STEPS` and `READ_DISTANCE`, the pre-14 rationale activity and Android-14+ protected permission-usage alias, plus Health Connect package visibility.
3. Existing BNYAD minimum SDK 24 is preserved. Stable Health Connect SDK declares min 26, so a narrowly scoped manifest merge override is paired with a separate bridge class instantiated **only on API 28+** (Health Connect's supported minimum). API 24–27 returns unavailable without loading that bridge. Release QA must verify app startup on API 24/25/26/27 as well as supported versions; do not remove the guard or silently raise BNYAD's minimum SDK.
4. On Android 9–13 use the official Health Connect app with a compatible Google-services device. Android 14+ uses system Health Connect. Sources must write/sync data; BNYAD does not run its own pedometer. Available newer system step aggregation is included without a source filter.
5. In Play Console, complete/update the **Health apps declaration** and requested Health Connect data types/use cases (steps and optional distance for fitness/activity display), Data safety disclosures, and the public privacy policy. The in-app rationale supplements that policy; it does not automatically update the public policy or Console. The release developer handles submission/review.
6. Existing Gradle 8.14 needs a compatible JDK, not Android Studio's current Java 25. JDK 17 was already available locally; used per command, not a global configuration change. Android SDK command-line tools/license status also needs review by the developer (`flutter doctor` reported them missing/unknown); do not auto-accept licenses.

## Validation and remaining physical-device QA

Automated tests cover calculations, median/outlier handling, incomplete/missing/duplicate dates, confirmation/cooldown/caps, manual override and persistence, account/backend isolation, denial/revocation, null versus zero, corrections, stale asynchronous results, midnight and clock events, failures, bounded channel payloads, malformed provider results, Arabic/Kurdish numeric input, consent UI, and light/dark + RTL layouts at 280/320/375/430/1024 px. They use **mocked** health providers/channel responses, not real sensors or OS authorization sheets.

Browser preview: `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8765 --no-web-resources-cdn -t lib/main_demo.dart`. Use only fictional data. The widget and details explicitly say **SIMULATED STEPS / DEMO ONLY**. Demo preferences are saved separately; production health reads are not available on Web.

Run `flutter analyze`, `flutter test`, `flutter build web --no-web-resources-cdn`, `flutter build ios --debug --no-codesign --flavor dev -t lib/main_development.dart`, and an Android debug build with compatible Java. Unsigned builds are compilation checks, not installation or real-health verification. Production/store-signed builds require the other developer's existing private release configuration.

Before release, record physical iPhone and Android evidence for:

- Permission granted, denied, partially granted (steps yes/distance no), revoked in OS settings, and reconnected.
- iOS limited-history/unknown read access and unavailable/locked health database; Android missing/updating Health Connect and unsupported devices.
- No data versus a true zero; totals compared with Health/Health Connect and configured source priorities.
- Overlapping phone/watch steps without double counting, late watch sync, edited/deleted historical health records and subsequent refresh.
- Restarting the app and the device, local midnight, DST, travel/timezone and manual-clock changes (including a change during a read).
- User-confirmed full days only; manual goal, restored recommendations, acceptance and seven-day cooldown.
- Logout/account switch and disconnect; no other-account totals/consent and no health records in network traffic/storage/logs.
- The original nutrition targets remain unchanged, existing food/water/weight/premium/navigation behavior still works, EN/AR/Sorani, VoiceOver/TalkBack, large fonts and real phone widths.

**Real HealthKit/Health Connect permission sheets, sensors, OS source merging and watch synchronization have not been validated on physical devices by automated/browser tests. They remain mandatory release gates.**

## Recorded checks — 16 October 2026

- Flutter analysis: no issues.
- Full automated suite: 212 passed, including 80 new step-tracking tests and the existing Today’s Meals regression coverage.
- Production Flutter Web JavaScript build: passed. Existing `flutter_timezone` WebAssembly dry-run warning remains; a Wasm build is not claimed.
- iOS development device build with codesigning disabled: passed, including native HealthKit queries and localized resources. Existing `mobile_scanner`/MLKit Apple-Silicon simulator and several plugins' Swift Package Manager warnings remain; this was a device-target compilation, not simulator or signed-device QA.
- Android debug APK: passed with the existing Gradle wrapper and per-command JDK 17. Native bridge, rationale activity, aggregate calls, permission contracts and manifest compiled. Merged manifest retains min SDK 24 / target 36 with only the two added read-health permissions. Existing Gradle/AGP/Kotlin future-support warnings remain.
- Local browser UI at 320px: original calorie/macro widgets retained; step details opened; a fictional manual goal of 7,500 persisted after reload, recommendations paused, and the 2,200-kcal food allowance did not change. English, Arabic and Sorani RTL previews use explicitly simulated steps, not device health data.
- No backend/database changes, deployments, store submissions, real health reads, production test writes or purchased services.
