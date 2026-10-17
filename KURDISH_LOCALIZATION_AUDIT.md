# BNYAD Kurdish Sorani localization audit — approved repair results

Updated 2026-10-17. This section supersedes the original read-only audit preserved below.

## Current outcome

Confirmed application-controlled localization defects L01–L10 have been addressed in code. **Implementation and automated checks pass; full native-device, browser and native-speaker certification remains PARTIAL/UNVERIFIED.** This is not a claim of perfect grammar or every possible screen state passing.

Original BNYAD design, authentication checks, user records, nutrient/step formulas, premium pricing/entitlements and native health reads are preserved. No production connection, deployment, store submission, purchase or database migration was performed. Gemini stayed off in all previews/tests; backend AI tests used mock responses only.

## Delivery revisions

Branch in both official repositories: codex/bnyad-stability-2026-10-13.

- Main implementation commit: **313fdc9aa2cc7207c6b0a20fbdf87bbaec21933b**.
- Backend implementation commit: **5b6fc19dedcbe0f4fb041012b20470edc52cbf95**.
- This audit report is delivered in a subsequent documentation commit on the same branch. The final verified branch tip is reported in the task's completion message.
- Backend push and remote hash were verified. Main implementation/report delivery is verified before the completion message.
- The existing root and vercel-api Vercel configurations retain Git deploymentEnabled=false; no deployment commands were run.

## Issue-by-issue repair status

| Audit issue | Implemented repair | Verification / remaining boundary |
| --- | --- | --- |
| L01 — missing “or” | Added matching EN/AR/Sorani keys; actual literal lookup checks now complement dictionary-key checks. | PASS: unit test and Sorani welcome captures; no literal English separator. |
| L02 — English leaks | Localized notification tooltip, calorie “of”, target comparison, premium days-remaining and test notification. Replaced the splash AI claim with a localized wellbeing footer, not an assertion that AI is active. | PASS: source/lookup/placeholder tests; selected widgets rendered. Conditional expiry/delta and delivered native test notification still need device review. |
| L03 — framework locale/date | MaterialApp now uses ckb, with ku compatibility. Added app-owned Sorani Material, Cupertino and Widgets delegates because installed Flutter lacks Sorani. Official delegates serve EN/AR. Sorani Gregorian month/day names replace English dates. | PASS: real framework picker, locale/direction/context-menu/date tests for all three languages; dashboard/progress renders. New framework wording still needs native review. |
| L04 — numeral entry | Shared finite decimal/integer parsing accepts Latin, Arabic-Indic and Eastern Arabic-Indic digits; Arabic decimal separator and valid Arabic grouping supported. Phone/OTP normalize before ASCII filters; measurements, macros, barcode entry and local diagnostic profile use normalized parsing. | PASS: all three scripts, precision, malformed/nonfinite input, phone/OTP fields and real weight dialog. Reminder input also fixed; see below. |
| L05 — RTL numbers | LTR isolates preserve minimum/maximum, date ranges, step count/goal, water count/goal, phone prefix and measurement fragments inside RTL sentences. | PASS: low-to-high body-fat range, start-to-end week range and count/goal shown correctly in Sorani captures. Calculations/chart chronology unchanged. |
| L06 — ckb helper gaps | Food names/servings/groups, meal/AI language selection, bone suffix, health guidance and direction accept ckb alongside ku. | PASS: all 605 catalog entries match for ckb/ku; locale persistence/switching and legacy sessions pass. No user-data language migration. |
| L07 — native/notifications | Localized iOS camera/photo descriptions; existing HealthKit wording/entitlements retained. Android rationale uses saved app language and RTL. Local notification names/body and pending reminders follow language changes. Optional authored notification maps added to admin/API/client. | PASS: native compilation, plist lint, mocked payload/route tests; PARTIAL: migration, actual OS permission/notification delivery not exercised. |
| L08 — product/wording | Daily-plan premium promise corrected in EN/AR/Sorani. Android/web renewal wording separated from Apple wording. Corrected rice/soup labels, fridge/freezer inconsistency, medication comma instruction, subscription-management label and body-fat disclaimer. Barcode platform copy now mentions iOS/Android. | PASS for targeted semantic/copy changes; PARTIAL for grammar. No pricing, entitlement, payment or AI-feature behavior changes. |
| L09 — narrow auth | Flexible welcome button labels, wrapping password/OTP actions and explicit bundled font fallback on affected button/dropdown styles. | PASS: EN/AR/Sorani, 320/430 auth regression tests and selected screenshots; no captured overflow. Actual platform fonts/keyboard/accessibility remain manual. |
| L10 — chart painting | Fixed top-border stroke alignment only. | PASS: progress screen renders and weight update test without the previous paint assertion. No statistic/calorie formula changes. |

### Reminder numeric entry: additional confirmed framework limitation

The installed Flutter stock text-time parser calls int.tryParse directly. It cannot parse Arabic/Persian digits, even under an RTL locale. [lib/l10n/localized_time_picker.dart:1](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/lib/l10n/localized_time_picker.dart:1) provides localized, validated 24-hour numeric entry for Arabic/Sorani plus the existing optional clock dial. English keeps its original picker. Only the reminder input UI changes; stored TimeOfDay and notification semantics are unchanged.

The weight dialog also now owns/disposes its controller with its widget. The regression test exposed early disposal during the exit animation; this is fixed without modifying weight-history or calorie-target behavior.

## Verification results

- **Flutter analysis: PASS, no issues.**
- **Full Flutter suite: PASS, 263 tests** (244 original + 19 added regression cases).
- **Opt-in widget render suite: PASS, 96 cases, 284 captures**, zero recorded Flutter rendering exceptions. 94 captures each for EN/AR, 96 for Sorani; the extra Sorani captures include the manual step-goal interaction. These are state/viewport captures, not 284 screens.
- **Backend: PASS, 65 tests**, including validation, locale selection, admin authentication, reject-before-write and authenticated inbox tests with mocked Prisma. Type checking and Next.js build passed. Matching notification source is in both repositories.
- **Android: PASS**, existing ARM64 offline debug variant compiled with installed JDK 21/SDK 36. APK ID verified as com.bnyad.app.dev; INTERNET is absent. No installation or real Health Connect reading was performed during this repair.
- **iOS: PASS**, unsigned physical-device profile build, dev scheme, main_iphone_preview.dart; ID com.nutrify.bnyad.dev. Not signed, installed or launched as part of this repair. Existing App Store and Health Test installations untouched.
- **Flutter Web: PASS**, debug demo bundle compiled without external Web-resource CDN. Browser navigation was not performed.
- **iOS localized plist files: PASS**, en/ar/ku/ckb parsed with plutil.
- Existing activity/meal tests retain light/dark, RTL and large-text coverage. Full-app dark-mode and accessibility-device coverage remain incomplete.

iOS emits existing third-party Swift Package Manager / Apple-Silicon simulator compatibility warnings, including mobile_scanner/MLKit dependencies. The physical-device compilation passes; simulator compatibility is not claimed. No unrelated plugin upgrades were made.

### Numeral scope

Decimal representation is normalized before existing validation. Invalid/nonfinite values are rejected, not rounded or guessed. Comma remains an existing decimal-input convention; malformed separators are rejected. Weight/measurement/macro/OTP/phone/manual barcode/profile fields and step goals are covered. Existing food portions, production onboarding age/height/weight and water quantities use sliders/steppers/fixed actions rather than new free-text fields; their existing calculation tests still pass. No new nutrition calculations or replacement input architecture were introduced.

### Language persistence and notification content

The added fixture test switches English → Sorani → Arabic → Sorani → English → Sorani, then recreates AppState. Language/RTL, 1500 ml fictional water intake and the 2200-calorie food target are preserved. Language saves are serialized to avoid out-of-order preference/API updates.

New authored notification maps are selected on each inbox render, so cached translated messages switch languages too. Legacy single-language messages, user names, product brands, shopping/supplement text and old AI content are preserved rather than automatically translated. The admin author must supply translations for new multilingual content.

## Visual coverage after repair

Primary inventory remains **17 surfaces**, with **16 represented by selected widget renders**. Barcode camera remains unverified visually. No surface is certified across every state and perfect grammar.

| Surface | Selected visual verification | Still unverified |
| --- | --- | --- |
| Welcome/login/registration/OTP | Sorani 320/430 plus all-language render/no-overflow checks; localized phone/OTP entry and validation | Guest-state variants, real SMS/backend, native keyboard/accessibility |
| Onboarding | All five steps and local-calculator result, 320/430 | Every selection/error permutation, physical device |
| Dashboard | Greeting/date/calories/macros/activity and scrolled meals/water areas | Full screen-reader order, all live-account states |
| Food log/database/search | Initial fixture logs, Sorani search, no-match, both widths | Every serving/preparation/amount/favorites variant; external barcode |
| Step activity/details | Mock totals/estimated calories, goal and info dialogs, both widths | Native health/OS permissions, denied/error/history delivery |
| Daily meal plan/recipes | Existing fixture plan and ingredient form, both widths | Live AI generation/regeneration; Gemini remains off |
| Profile/settings | Account/language/theme/reminder sections, deletion confirmation canceled | Account mutation, native reminder delivery, all macro editor cases |
| Premium | Authored daily-plan wording and sheet layout | Store sandbox, price/restore/purchase errors; no purchases |
| Notifications | Empty-state layout; multilingual content selection covered by unit/API tests | Populated real inbox, FCM delivery |
| Progress/weight | Chart, date range, weight dialog and local-digit validation | Every history shape/native fonts |
| Body fat | Corrected numeric range and disclaimer | Camera/photo/provider branches |
| Shopping | Empty and long-name fictional entry | Every completion/duplicate/AI response state |
| Medical citations/login-required/splash | Selected original widgets at both widths | Complete animations, external links, every action |
| Navigation / reminder entry | Dock and localized time dialog, both widths | Full browser navigation and every locked/accessibility state |
| Barcode camera/results | Source reviewed | Camera, OS permission and product/result sheets |

The screenshot harness uses real existing widgets, explicit bundled fonts and mock API/storage/health. Its 12,345 steps and walking calories are **simulated fixtures**, not native testing. Remaining test-engine fallback glyphs (for example the approximate sign in some renders) are not certified as native defects. Captured debug ribbons are test UI, not production content. No personal health values or account credentials are stored in evidence.

Evidence and repeatable checks:
- [test/localization_repair_test.dart:1](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/test/localization_repair_test.dart:1)
- [tool/localization_visual_test.dart:1](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/tool/localization_visual_test.dart:1)
- [Render summary](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/build/localization-evidence/render-results.json)
- [Sorani dashboard](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/build/localization-evidence/dashboard-320-ku.png)
- [Sorani body-fat range](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/build/localization-evidence/body-fat-320-ku.png)
- [Sorani OTP](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/build/localization-evidence/otp-sorani-digits-320-ku.png)
- [Sorani onboarding](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/build/localization-evidence/onboarding-step-5-320-ku.png)
- [Localized reminder entry](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/bnyad/build/localization-evidence/localized-time-picker-320-ku.png)

Run the opt-in visual test from the repository to regenerate build/localization-evidence. PNGs/build outputs are ignored and not committed; the portable harness is committed.

## Remaining work / approvals

1. **Backend migration approval required before release:** the release developer must review/approve and apply vercel-api/prisma/notification_translations.sql to the intended backed-up database before deploying the new Prisma/API build. It is additive/nullable and was not applied here. No new environment variables. See KURDISH_LOCALIZATION_HANDOFF.md.
2. Native Sorani review is still needed for the new framework vocabulary, sensitive health/consent/disclaimer wording, category names, terminology consistency and all catalog descriptions. Targeted fixes are not a professional grammar certificate.
3. Actual iPhone/Samsung permission sheets, rationale, notification delivery after language switch/reboot, real health totals, platform font fallback, screen readers, large text and store sandbox flows require manual release QA. The Samsung was not attached during this repair. Unsigned iOS output is not a device test.
4. Browser security previously prevented localhost observation. No alternate browser bypass was attempted. Safe isolated Flutter rendering was used instead. Actual Safari/Web navigation remains unverified.
5. External privacy/terms/deletion pages and live AI output were not opened/enabled. Preserve user/brand text and properly label legacy/provider content; do not silently translate or overwrite user records.
6. No nutrition, step-formula, premium entitlement, authentication or OS-security bypass is needed for the remaining checks.

---

# Historical read-only audit at 481a00aa04cb8c465a0985bd2c551691d722bd99

The following records the original findings, not current unfixed status. Source links refer to the baseline revision; historical evidence remains local. The approved repair results above supersede “no changes” / “await approval” statements below.

# BNYAD Kurdish Sorani localization audit

Audit date: 2026-10-17. Target: Central Kurdish / Sorani (ckb; legacy internal identifier ku).

## Verdict

**PARTIAL — BNYAD has substantial Sorani coverage, but complete, professional Sorani support is not verified and several concrete defects prevent a full pass.**

The translation dictionaries have matching keys and the bundled food catalog contains Sorani names throughout. That does not establish that every visible string, numeric input, native permission, dynamic result or UI state is localized. Confirmed problems include missing lookup coverage, hardcoded English, untranslated framework defaults, localized-digit rejection, ambiguous/reversed numeric ranges under RTL, and incorrect product copy.

This is an audit, not a localization implementation. Application/backend source, authentication, nutrition calculations, subscriptions, step tracking and production configuration were not changed. Gemini remained disabled. No deployment, store submission, production account, production database access, purchase, commit or push was performed. This report is the only repository addition; audit scripts and fictional render artifacts are outside the repositories.

## Revision and scope

Existing development branch: codex/bnyad-stability-2026-10-13.

- Main local HEAD and remotely verified branch tip: **481a00aa04cb8c465a0985bd2c551691d722bd99**.
- Backend local HEAD and remotely verified branch tip: **a47836f376751a7e33636dd8e4cc9baccedb0a83**.
- The relevant AI-contract and notification-admin files in the main repository's vercel-api copy match the backend repository copies.
- Source inventory: **97 Dart files under lib**, including **15 screen files**. Automated heuristics found **27 named Screen/Page/Sheet/Dialog classes**; manual inspection additionally identified _AiShoppingSheetBody, bringing named surface widgets to **28**. These counts are not a promise that all runtime branches have been exercised.
- **17 primary screen/route surfaces** are counted below. Welcome, password login, registration, OTP and guest-name are states of one LoginScreen, not five separate routes. Premium is counted as a primary user destination despite being implemented as a sheet. StepDetailsScreen and the barcode page live outside lib/screens.
- **11 additional named overlay/component surfaces**, including one development-only local health-profile dialog, are separate from those 17. Inline consent, confirmation, history and picker dialogs are also inventoried below. There are **29 dialog/sheet/date/time-picker invocation sites**, not 29 additional unique screens.

### Required coverage counts

- Primary screens discovered: **17**.
- Primary surfaces visually reviewed using selected isolated Flutter renders: **16**. The native barcode camera page was not visually tested.
- Actual browser pages navigated/visually inspected during this audit: **0**.
- Primary screens fully certified translated across every state, native interaction and grammar review: **0**. This means none can be certified complete from this evidence, not that all their labels are untranslated.
- Primary screens with confirmed app-controlled missing/English text: **at least 6** — Login/Welcome, Dashboard, Onboarding, Settings, Splash and Progress/Weight. Conditional states are included; they are distinguished in the findings.
- Other confirmed issues affect body-fat numeric presentation, premium product claims, notifications and native permissions. They are not silently included in the missing-text count.
- Render artifacts: **85 captures covering 46 distinct named states/components**, at 320×900 and/or 430×900 logical pixels. Initial screen states were rendered at both widths; registration/OTP follow-through was captured at 430 only. This is not 85 screens and is not 85 clean passes.

### Important visual-test limitation

The browser tool's security policy rejected access to the existing localhost preview. No alternate browser, indirect page-access method or security workaround was used. Consequently, Safari navigation, browser font fallback, actual Web layouts and whole-app navigation after switching remain **UNVERIFIED**.

Instead, an isolated Flutter widget-render harness mounted existing screens with real bundled fonts, mock API/storage and fictional data. It did not run a browser. It used an in-memory simulated health provider, never real HealthKit or Health Connect data. Rendered steps/calories are test fixtures, not new device verification.

Some controls without an explicit font family render with the headless test engine's square/default glyphs even after bundled fonts are loaded. These screenshots cannot certify those controls' real-device glyph rendering or exact text widths. The two narrow authentication overflows are therefore **test-reproduced layout risks requiring browser/device confirmation**, not asserted as proven native defects. Red corner ribbons/default test glyphs are not reported as production translation bugs. Initial splash captures precede some animation text; the English footer finding is source-backed, not falsely claimed visible in that frame.

## Status definitions

- PASS: the stated narrow check passed; never means all possible states passed.
- FAIL: a specific defect is demonstrated by source, a focused probe or a reliable rendered observation.
- PARTIAL: translated content exists but a known gap or incomplete state coverage remains.
- UNVERIFIED: no reliable evidence for the requested runtime/platform/language-quality claim.

Grammar is marked PARTIAL where a candidate needs correction/review and UNVERIFIED elsewhere. No native-speaker certification was obtained.

## Primary screen matrix

| Screen | Kurdish | RTL | Grammar | Visual Test | Issues |
| --- | --- | --- | --- | --- | --- |
| LoginScreen: welcome/login/registration/OTP/guest | FAIL | PARTIAL | UNVERIFIED | PARTIAL | L01 missing “or”; L04 localized digits; L09 narrow authentication layout risk; phone-prefix bidi review. Welcome/password at both widths, registration/OTP at 430; guest state source-only. |
| OnboardingScreen: five steps/results | FAIL | PARTIAL | PARTIAL | PARTIAL | L02 conditional “vs”; terminology/input-unit consistency; all five steps and default result rendered, not every choice/error. |
| DashboardScreen: calories/macros/meals/water | FAIL | PARTIAL | UNVERIFIED | PARTIAL | L02 “of” and notification tooltip; L03 English date; L05 ratios; dynamic saved names are not retranslated. |
| FoodLogScreen, database/search | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | 605 catalog names covered; historic single-name logs/favorites and provider labels can remain in original language. Search, Sorani query and no-match captured. |
| ScannerScreen: food/fridge | PARTIAL | PARTIAL | PARTIAL | PARTIAL | L08 fridge/freezer inconsistency; result/error/confirmation branches only statically inspected; camera/provider execution unverified. |
| MealPlanScreen: daily plan/meal details | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | Fixture names/ingredients/instructions localize; legacy/missing-language fallback can show English. Regeneration/live responses unverified. |
| ShoppingListScreen | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | Empty/long-name fixture states captured; user names deliberately preserved; AI shopping sheet source-only. |
| WeeklySummaryScreen: progress/weight | FAIL | FAIL | UNVERIFIED | PARTIAL | L03 English month; L04 localized weight rejected; L05 range bidi; L10 chart paint assertion. |
| BodyFatEstimatorScreen | PARTIAL | FAIL | PARTIAL | PARTIAL | L04 localized measurements; L05 percentage range visually reverses; L08 disclaimer wording; photo flow unverified. |
| NotificationsScreen | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | Empty state translated; L07 server title/body are single-language and displayed verbatim. Populated/native delivery not exercised. |
| SettingsScreen/profile/account | FAIL | PARTIAL | PARTIAL | PARTIAL | L02 conditional “days left”; L03 built-in picker defaults; L07 reminder language; L08 premium management wording; deletion confirmation captured, never confirmed. |
| Premium paywall | PARTIAL | PARTIAL | PARTIAL | PARTIAL | L08 weekly-plan promise is incorrect; Apple-only renewal terms are shared with Android; purchase/restore/store-native errors unverified. |
| MedicalCitationsScreen | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | Surrounding descriptions are Sorani; original English bibliographic titles/authors remain intentionally identifiable. External sources not opened. |
| LoginRequiredScreen | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | Main message translated; actual navigation, framework accessibility and headless default button glyphs prevent a full pass. |
| SplashScreen | FAIL | PARTIAL | UNVERIFIED | PARTIAL | L02 hardcoded “Powered by AI”; complete animation not visually certified. |
| StepDetailsScreen/activity widget | PARTIAL | PARTIAL | UNVERIFIED | PARTIAL | 57 vocabulary entries covered; L05 ambiguous step/goal ratio; manual goal and calorie-information dialogs captured; permissions/history branches source-reviewed. |
| BarcodeScannerPage | PARTIAL | UNVERIFIED | UNVERIFIED | UNVERIFIED | Localized lookup/error/manual labels exist; provider names and /100g unit strings; actual camera/native permissions and result sheets need testing. |

PARTIAL visual status means selected widget states were inspected, not browser or device end-to-end approval.

## Confirmed findings and exact references

### L01 — Missing lookup key renders literal English “or” (P2)

Welcome calls [lib/screens/login_screen.dart:1254](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L1254) with get('or'). That key is absent from all main dictionaries. [lib/l10n/app_localizations.dart:18](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L18) returns the key itself when absent. The literal “or” is visible in [welcome-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/welcome-320.png).

Matching EN/AR/Sorani key sets does not catch a key missing from every language. Future checks must compare actual lookup call sites with defined keys, including nested/dynamic access.

### L02 — App-controlled English escapes the translation system (P2)

- Dashboard notification tooltip: “Notifications”, [lib/screens/dashboard_screen.dart:102](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/dashboard_screen.dart#L102). This is user-facing accessibility/hover text, not an internal log.
- Dashboard calorie caption: “of”, [lib/screens/dashboard_screen.dart:331](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/dashboard_screen.dart#L331). Confirmed in [dashboard-430](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/dashboard-430.png).
- Splash: “Powered by AI”, [lib/screens/splash_screen.dart:312](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/splash_screen.dart#L312). Source-backed animation branch; also needs review because AI may be disabled.
- Onboarding result delta: “vs”, [lib/screens/onboarding_screen.dart:934](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/onboarding_screen.dart#L934). Conditional when the chosen target differs from maintenance; default rendered stay-healthy fixture did not exercise this line.
- Settings premium expiration: “($daysLeft days left)”, [lib/screens/settings_screen.dart:541](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/settings_screen.dart#L541). Conditional active subscription with expiration; the fixture without an expiration did not visually exercise it.
- Test notification body: “Notifications are working!”, [lib/services/notification_service.dart:401](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/services/notification_service.dart#L401), called by the settings test-notification control at [lib/screens/settings_screen.dart:1274](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/settings_screen.dart#L1274). Native delivery was not triggered.
- Android channel names/descriptions remain English; see L07.

Language self-names, BNYAD/Google/Apple Health/Health Connect, source citations, protocol names, BMR/TDEE/BMI and legitimate product names are not automatically untranslated-text defects. Unit notation needs an explicit consistent product policy rather than indiscriminate replacement.

### L03 — Sorani labels are not the application's actual Material locale (P1)

[lib/main.dart:161](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main.dart#L161) configures themes and a Directionality wrapper, but no locale, supportedLocales or localization delegates. Changing state.lang changes app labels/direction without installing corresponding Material/Cupertino translations.

The focused probe reports the default framework locale as en_US and the Material cancel label as “Cancel”. The dashboard formats its date through MaterialLocalizations at [lib/screens/dashboard_screen.dart:755](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/dashboard_screen.dart#L755); the Sorani render shows “Sat, Oct 17”.

Settings and supplements use built-in time pickers without locale overrides, e.g. [lib/screens/settings_screen.dart:1307](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/settings_screen.dart#L1307) and [lib/screens/dashboard_screen.dart:2245](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/dashboard_screen.dart#L2245). Built-in picker controls and framework tooltips/accessibility cannot be certified Sorani from the custom dictionary.

Separately, [lib/utils/weekly_summary_stats.dart:118](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/utils/weekly_summary_stats.dart#L118) defines English/Arabic month labels, with no Sorani branch. The Sorani weekly heading therefore contains “Oct”. [progress-weight-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/progress-weight-320.png) shows this independently of the Material locale issue.

Recommended scope after approval: wire supported framework localization carefully, verify actual ckb availability/delegate behavior in the installed Flutter version, and provide missing Sorani framework messages where necessary. Merely adding Directionality is insufficient. Do not claim that a package/delegate provides Sorani until tested.

### L04 — Sorani/Arabic/Persian numeral entry is inconsistent (P1)

- Phone processing removes non-ASCII digits using a regular expression at [lib/screens/login_screen.dart:64](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L64) and [lib/screens/login_screen.dart:108](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L108). A user entering local-script digits can be rejected or lose their number.
- OTP uses FilteringTextInputFormatter.digitsOnly at [lib/screens/login_screen.dart:867](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L867) and ASCII integer validation at [lib/screens/login_screen.dart:237](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L237). Entering ١٢٣٤٥٦ in the isolated OTP test leaves no usable code; [otp-sorani-digits-430](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/otp-sorani-digits-430.png).
- Body measurements use double.tryParse after comma replacement only: [lib/screens/body_fat_estimator_screen.dart:56](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/body_fat_estimator_screen.dart#L56).
- Weight dialog uses the same approach at [lib/screens/weekly_summary_screen.dart:50](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/weekly_summary_screen.dart#L50). After entering ٧٥.٥ and tapping Save, the dialog stays open with no localized invalid-value explanation: [weight-sorani-digits-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/weight-sorani-digits-320.png).
- Focused parsing probes: 75.5 parses; ٧٥.٥ and ۷۵.۵ return null.
- In contrast, the step-goal parser already normalizes Arabic/Persian digits at [lib/activity/step_widgets.dart:594](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/activity/step_widgets.dart#L594). Reuse that principle for other input, without changing calculations.

Accept common digit scripts and decimal separators at input boundaries; retain stable numeric values and technical/API identifiers internally. A choice to display Western digits is not itself a defect, but inputs should not silently reject what the user's keyboard supplies.

### L05 — Numeric ranges/ratios need bidi isolation (P1)

- Body-fat source formats minimum then maximum at [lib/screens/body_fat_estimator_screen.dart:472](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/body_fat_estimator_screen.dart#L472), but the RTL render shows the range visually as 25.1% — 15.1%, instead of an unambiguous low-to-high sequence: [body-fat-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/body-fat-320.png). The calculation was not changed.
- Weekly range is constructed as start–end at [lib/utils/weekly_summary_stats.dart:124](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/utils/weekly_summary_stats.dart#L124) but appears as “Oct 17–11” in [progress-weight-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/progress-weight-320.png).
- Activity source builds count / goal at [lib/activity/step_widgets.dart:92](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/activity/step_widgets.dart#L92); fixture count 12345 and goal 5000 display in the opposite visual order in [dashboard-430](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/dashboard-430.png). RTL reading conventions may be interpreted differently, so explicitly label/isolate the ratio rather than leaving its meaning ambiguous.
- Phone country prefix appears as “964+” in the registration/OTP render; inspect [lib/screens/login_screen.dart:72](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L72) and [lib/screens/login_screen.dart:813](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L813). The input has a deliberate LTR wrapper at [lib/screens/login_screen.dart:1041](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L1041), but the surrounding confirmation sentence also needs mixed-direction review.
- Body-fat profile context, progress kg/g, barcode /100g and time/date strings mix localized labels and Latin units/numerals. Examples: [lib/screens/body_fat_estimator_screen.dart:328](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/body_fat_estimator_screen.dart#L328), [lib/screens/weekly_summary_screen.dart:201](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/weekly_summary_screen.dart#L201), [lib/widgets/barcode_scan_flow.dart:891](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/widgets/barcode_scan_flow.dart#L891).

Isolate number-unit/range fragments while preserving surrounding RTL. Do not globally reverse charts or change numeric values. The observed weekly chart lays out days in RTL; product expectations for chronology and accessibility order still require manual review.

### L06 — ckb support is inconsistent in lower-level helpers (P2; guarded in normal session path)

Direct probes demonstrate:

- FoodItem.getLocalizedName('ku') returns “دۆڵمەی کوردی”; passing 'ckb' returns “Dolma (Kurdish)”. See [lib/models/food_item.dart:239](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/models/food_item.dart#L239); serving-label selection has the same gap at line 245.
- normAiLang('ckb') returns 'en': [lib/utils/ai_trilingual_strings.dart:4](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/utils/ai_trilingual_strings.dart#L4).
- Meal locale normalization only handles ar/ku: [lib/models/meal.dart:41](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/models/meal.dart#L41).
- Food-group titles/options only handle ar/ku: [lib/constants/food_group_registry.dart:27](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/constants/food_group_registry.dart#L27) and [lib/constants/food_group_registry.dart:51](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/constants/food_group_registry.dart#L51).
- AppState.isRTL recognizes ar/ku, not raw ckb: [lib/providers/app_state.dart:290](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/providers/app_state.dart#L290).

**Important counter-evidence:** this is not a demonstrated broken server-session restoration. Current setLang normalizes ckb to ku at [lib/providers/app_state.dart:716](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/providers/app_state.dart#L716); preferences normalize it at [lib/providers/app_state.dart:381](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/providers/app_state.dart#L381); API profile parsing normalizes it at [lib/services/api_service.dart:821](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/services/api_service.dart#L821). A mock server profile with language ckb restored as ku, RTL true, with the Sorani food name. A suspected restore regression was tested and ruled out for this path.

Consolidate boundary normalization and add direct canonical-locale tests after approval. Do not remove existing ku compatibility or migrate user data blindly.

### L07 — Notification and native permission language gaps (P2)

**Notifications**

- Native Android channel names/descriptions are English at [lib/services/notification_service.dart:18](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/services/notification_service.dart#L18) through line 27.
- The test-notification body is English (L02).
- Meal/supplement scheduled titles use app translations at scheduling time: [lib/providers/app_state.dart:1741](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/providers/app_state.dart#L1741) and [lib/providers/app_state.dart:1913](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/providers/app_state.dart#L1913). However language persistence only explicitly reschedules the weekly digest at [lib/providers/app_state.dart:724](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/providers/app_state.dart#L724). Existing meal/supplement notifications can retain their old language until a reschedule/restart. Source-backed lifecycle gap; OS delivery after a switch is unverified.
- Notification list titles/bodies are displayed directly at [lib/screens/notifications_screen.dart:118](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/notifications_screen.dart#L118) and [lib/screens/notifications_screen.dart:130](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/notifications_screen.dart#L130); foreground/background pushes likewise use supplied text at [lib/services/push_service.dart:11](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/services/push_service.dart#L11) and [lib/services/push_service.dart:73](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/services/push_service.dart#L73).
- Backend notification publishing accepts one title/body pair, stores it once and broadcasts that pair: [vercel-api/app/api/admin/notifications/route.ts:43](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/vercel-api/app/api/admin/notifications/route.ts#L43), line 62, line 87. No locale-specific fields or recipient language selection exist there. An English admin message remains English in Sorani UI. This is a content contract limitation, not proof that current production notifications are English.

**iOS**

- Health-sharing purpose text exists for ckb/ku: [ios/Runner/ckb.lproj/InfoPlist.strings:1](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/ios/Runner/ckb.lproj/InfoPlist.strings#L1) and [ios/Runner/ku.lproj/InfoPlist.strings:1](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/ios/Runner/ku.lproj/InfoPlist.strings#L1).
- Those localized files contain only the HealthKit description. Camera and photo-library descriptions remain English in [ios/Runner/Info.plist:7](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/ios/Runner/Info.plist#L7) and line 9; equivalent development plists also need coverage.
- Native permission chrome and which localized purpose text iOS selects depend on platform/per-app language settings, not just Flutter state.lang. This audit did not open fresh permission prompts or change permissions.

**Android**

- The Health Connect privacy activity has Sorani copy, but selects it using Locale.getDefault().language, not BNYAD's saved language: [android/app/src/main/kotlin/com/bnyad/app/HealthPrivacyActivity.kt:14](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/android/app/src/main/kotlin/com/bnyad/app/HealthPrivacyActivity.kt#L14) and line 25. English-system + Sorani-in-app can therefore show an English rationale.
- Main manifest application has no explicit supportsRtl declaration at [android/app/src/main/AndroidManifest.xml:27](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/android/app/src/main/AndroidManifest.xml#L27); programmatic native rationale layout has no explicit direction. Flutter's explicit direction works independently; native rationale RTL needs physical-device verification, not a blanket Android RTL failure claim.
- No Android localized values-ckb resources were found. BNYAD branding is intentionally unchanged.
- Android/iOS system permission names, Health Connect/Apple Health screens, keyboard, store checkout and share sheets are OS/provider-controlled. App-owned explanations can be localized; unsupported OS Sorani cannot be promised by changing Dart labels.

### L08 — Sorani wording and product-copy review (P2)

The following are **review candidates**, not certified replacement translations. Approve terminology with a native Sorani reviewer before bulk edits.

| Key/context | Current Sorani | Concern | Exact source |
| --- | --- | --- | --- |
| categoryList.RiceDishes | خواردنەوەی برنج | Wording refers to rice beverages rather than rice dishes. | [lib/l10n/app_localizations.dart:2565](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2565) |
| categoryList.Soup | شۆربا و نیشاستە | “Starch” does not match the English soups/stews category meaning. | [lib/l10n/app_localizations.dart:2566](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2566) |
| scanFridge / description | سکانی فریزەرەکەم / فریزەرەکەت | Freezer versus fridge; other copy uses سەلاجە / ساردخانە. | [lib/l10n/app_localizations.dart:2406](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2406) |
| medicationsHint | بە بزر دابڕێنە… | Delimiter instruction is unclear; review intended “separate with commas”. | [lib/l10n/app_localizations.dart:2683](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2683) |
| premiumManage | بەڕێوەبردنی پسوولە | Invoice/receipt wording instead of subscription management. | [lib/l10n/app_localizations.dart:2601](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2601) |
| bodyFatStaticDisclaimer | …نەشێوانە و نە ئامێری پزیشکی… | Unclear wording in a sensitive disclaimer; native health-language review needed. | [lib/l10n/app_localizations.dart:2475](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2475) |

Terminology varies across ژیری دەستکرد / زیرەکی دەستکرد / AI, ماکرۆ / ماکڕۆ / ماکرۆس, ڕێچەتە / ڕێسپی, تەواوکەر / سوپلیمێنت and چەوری / بەز. These are not all necessarily wrong; establish an approved glossary rather than treating each synonym as a defect. Review spelling, spacing, punctuation, loanwords, singular/plural units and reading level across all main, step and AI strings and catalog descriptions.

**Confirmed product-copy problems, not just grammar:**

- Premium promises “AI-generated weekly meal plans” in English/Arabic/Sorani. Sorani key at [lib/l10n/app_localizations.dart:2590](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2590) is consumed by [lib/screens/premium_paywall_screen.dart:60](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/premium_paywall_screen.dart#L60) and [lib/main.dart:272](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main.dart#L272). BNYAD supports daily meal planning; this promise should say daily, not lead to a weekly feature implementation.
- Shared renewal terms at [lib/l10n/app_localizations.dart:2780](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2780) refer only to Apple ID/App Store, while the shared paywall consumes them at [lib/screens/premium_paywall_screen.dart:229](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/premium_paywall_screen.dart#L229). Android needs platform-appropriate wording; store billing behavior was not changed/tested.
- Barcode Web explanatory copy should be checked against actual supported platforms; [lib/l10n/app_localizations.dart:2655](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L2655) mentions Android/APK. Actual Web camera/product behavior is unverified.

### L09 — Narrow authentication layout risk (P2; test-only reproduction)

At 320 logical pixels, the unmodified widget harness captured a 16-pixel overflow on welcome and 35-pixel overflow on password login. At 430 those exceptions did not occur. Sources include the non-flexible welcome button text row at [lib/screens/login_screen.dart:1191](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L1191) and the two login action buttons in a fixed Row at [lib/screens/login_screen.dart:564](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L564).

See [welcome-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/welcome-320.png) and [login-password-320](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/login-password-320.png). Because test-default font fallback is imperfect in those controls, **do not treat those pixel sizes as verified Safari/iPhone measurements**. Retest with actual bundled/platform fonts, keyboard open, RTL and accessibility text before deciding the smallest layout fix. Registration follow-through at 320 was not successfully exercised.

### L10 — Weekly chart paint assertion (P2; not proven language-specific)

The isolated progress screen triggers a Flutter painting assertion at both 320 and 430:

“A Border can only draw strokeAlign different than BorderSide.strokeAlignInside on borders with uniform colors.”

[lib/screens/weekly_summary_screen.dart:534](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/weekly_summary_screen.dart#L534) builds a top-only border with centered stroke alignment at line 541. This obstructs clean visual certification of that chart even though other labels render. It is a general debug painting defect encountered during the audit, **not established as caused by Sorani or RTL**. Do not change calculation/chronology to fix a border-paint problem.

## Dynamic content and backend errors

### What is working structurally

- Main dictionaries: **602 leaf strings per locale**, matching key sets and nonempty values in English/Arabic/ku/ckb.
- Existing placeholder tests pass for the set of named placeholders in each corresponding value.
- AppLocalizations treats ckb and ku identically; StepStrings has **57 matching keys**; AiStrings has **21 matching keys**.
- Bundled database: **605 food entries**, all with nonempty Sorani names, none identical to their English name; no missing Sorani serving label where an English serving label exists. This is field coverage, not native linguistic certification of all foods.
- Food catalog Sorani names contain no Arabic-keyboard kaf/ya in the scan. The single main-map script-scan match is the intentionally Arabic language self-name; do not automatically rewrite that label.
- Fixture daily-meal names, ingredients and instructions use Sorani fields in the inspected renders.
- Common English authentication/network failures are localized by [lib/l10n/app_localizations.dart:122](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/l10n/app_localizations.dart#L122) before presentation at [lib/screens/login_screen.dart:192](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/login_screen.dart#L192), line 257 and line 479. The existing tests verify five representative messages.
- Account deletion displays localized success/failure labels at [lib/screens/settings_screen.dart:1645](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/settings_screen.dart#L1645). No deletion was performed.
- AI failures map local error codes through AiStrings rather than displaying raw provider messages, e.g. [lib/screens/scanner_screen.dart:126](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/scanner_screen.dart#L126) and [lib/screens/meal_plan_screen.dart:91](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/meal_plan_screen.dart#L91).

### Remaining dynamic limitations

- Saved LogEntry and FavoriteTemplate store a single name, not a language map: [lib/models/log_entry.dart:4](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/models/log_entry.dart#L4) and [lib/models/favorite_template.dart:6](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/models/favorite_template.dart#L6). Dashboard displays entry.name directly at [lib/screens/dashboard_screen.dart:1440](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/dashboard_screen.dart#L1440). Switching language will not retranslate older names; demo “Demo: oats and banana” illustrates this. Preserve user-entered/brand names; only relocalize catalog-backed names if safe identifiers exist.
- Meal getters fall back to other locales/legacy text when Sorani is missing, e.g. [lib/models/meal.dart:46](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/models/meal.dart#L46). AI helpers also prefer English fallback at [lib/utils/ai_trilingual_strings.dart:30](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/utils/ai_trilingual_strings.dart#L30). These avoid blanks but can expose English for old/incomplete records.
- Barcode names come from external providers/manual entries and can be a product's original language, not necessarily a translated description: [lib/widgets/barcode_scan_flow.dart:482](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/widgets/barcode_scan_flow.dart#L482). No external barcode request was made.
- User-entered supplement names, shopping items, display names and recipe ingredients are content, not automatically a localization defect.
- Admin notifications are a confirmed untranslated-content pathway (L07).
- No additional raw English authentication error leak was established in the inspected login/delete paths. English backend source messages alone are not proof of an English UI leak.
- Gemini was not enabled. Backend response validation requires trilingual fields and script checks at [vercel-api/lib/ai/contract.ts:30](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/vercel-api/lib/ai/contract.ts#L30) and line 39, but script checks do not establish natural Sorani, correct nutrition terms or fluent instructions. Live output, unusual ingredients, allergy warnings, rejection messages and legacy-result migration remain UNVERIFIED.

## Additional surfaces and state coverage

Source-reviewed named overlays/components beyond the primary matrix:

- Nutrient/supplement sheet _VitaminSheet: [lib/screens/dashboard_screen.dart:1880](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/dashboard_screen.dart#L1880). Initial sheet rendered; both tabs, scheduling, dosage errors and editing each existing reminder not exhaustively exercised.
- Food favorites _FavoritesSheet: [lib/screens/food_log_screen.dart:326](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/food_log_screen.dart#L326). Source reviewed; empty/populated/long-name variants require visual follow-up.
- Food search/portion sheet _FoodSearchSheet: [lib/screens/food_log_screen.dart:473](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/food_log_screen.dart#L473). Initial, Sorani search and no-match rendered; every category/preparation/oil/bone/serving/amount state not exhausted.
- Ingredient recipes _IngredientRecipeSheet: [lib/screens/meal_plan_screen.dart:1891](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/meal_plan_screen.dart#L1891). Initial form rendered; generation/live output/error branches unverified.
- Macro editor _MacrosEditorSheet: [lib/screens/settings_screen.dart:835](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/settings_screen.dart#L835). Source reviewed; visual input/validation follow-up needed.
- Manual goal _StepGoalDialog: [lib/activity/step_widgets.dart:607](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/activity/step_widgets.dart#L607). Rendered; localized-digit parser is covered by existing tests.
- Barcode confirmation/not-found/local-food picker: [lib/widgets/barcode_scan_flow.dart:401](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/widgets/barcode_scan_flow.dart#L401), line 732 and line 953. Source reviewed, not visually/device tested.
- AI shopping _AiShoppingSheetBody: [lib/widgets/ai_meal_plan_shopping_sheet.dart:67](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/widgets/ai_meal_plan_shopping_sheet.dart#L67). Source reviewed, not opened through real AI.
- LocalHealthProfileDialog: [lib/main_health_test.dart:255](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main_health_test.dart#L255). Development-only, English controls; not a production screen.

Inline surfaces reviewed in source include account deletion, food full-name information/delete confirmation, weight update, AI consent/estimate confirmation, health-sharing consent, completed-day selection, suggested-goal acceptance and native time pickers. Rendered dialogs include account deletion (cancel only), weight, manual goal, and walking-calorie information. Consent/history/pickers and all delayed/empty/error permutations are not claimed visually tested.

Development-only English banners/control panels are isolated at [lib/demo/demo_shell.dart:83](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/demo/demo_shell.dart#L83), [lib/main_health_test.dart:306](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main_health_test.dart#L306), [lib/main_iphone_preview.dart:105](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main_iphone_preview.dart#L105) and [lib/main_development.dart:32](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main_development.dart#L32). They must not be counted as untranslated production labels. The local test profile says “this iPhone” at [lib/main_health_test.dart:314](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/main_health_test.dart#L314) even when reused for Android; this is a dev-copy issue only.

Bottom navigation labels use translations at [lib/widgets/app_bottom_nav.dart:32](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/widgets/app_bottom_nav.dart#L32). Existing layout/navigation tests passed, but the full dock's Sorani screen-reader order, every locked state and browser navigation after a language switch were not newly verified by the isolated screen harness.

Water labels/buttons, dashboard meal status/delete dialogs, supplement controls, macro labels and step statuses reference translated app vocabularies. Their presence in source does not certify every runtime branch or natural wording.

## Automated verification and evidence

### Commands/results

- Flutter analysis with existing dependencies: **PASS — no issues found**.
- Existing Flutter test suite: **PASS — 244 tests**. Includes localization, authentication persistence, AI mocks/consent, nutrition, step calculations, native-preview isolation, navigation and meal layout tests.
- Existing localization audit plus two temporary targeted audit tests: **PASS — 5 tests**. These overlap the full suite's three localization tests and are not 249 distinct existing tests.
- Isolated render harness: **30 test cases completed**, producing **85 captures / 46 named states**. The harness intentionally records Flutter exceptions and continues. Its test-runner “passed” status **is not a clean visual pass**: two authentication captures recorded overflow and two progress captures recorded painting exceptions. See render-results.json and render-log.txt.
- Existing activity tests exercise widths 280/320/375/430/1024, en/ar/ku, light/dark and large text at [test/step_tracking_test.dart:779](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/test/step_tracking_test.dart#L779). Existing details tests begin at line 844.
- Existing meal layout tests exercise multiple widths, en/ar/ku and both themes at [test/todays_meals_layout_test.dart:150](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/test/todays_meals_layout_test.dart#L150); full-name dialog behavior at line 219. Passing these does not certify every other screen or actual browser fallback.

### Language switching

The isolated AppState/mock API test performed:

English → ckb (normalized ku) → Arabic → ckb → English → ckb.

Each transition preserved fictional water intake **1500 ml** and calorie target **2200**. A new AppState using the same mock storage restored **ku, RTL true, water 1500 ml** after asynchronous data loading completed. A mock server ckb profile also normalized correctly (L06). No production account was used.

This establishes the tested persistence/data invariants, not every stored field or real-device navigation/notification behavior. Whole-app navigation, concurrent save failures, purchase state and actual cold-start Sorani typography remain manual follow-up items.

### Reproducibility

Evidence is stored outside Git at:

[Audit evidence folder](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence)

- [UI inventory](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/ui-inventory.json)
- [Probe results](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/audit-probes.json)
- [Render results and captured text/errors](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/render-results.json)
- [Render log](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/render-log.txt)
- [Read-only UI scanner](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/ui_scan.dart)
- [Focused audit tests](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/probes_test.dart)
- [Isolated screen-render harness](/Users/macbookshop/Documents/Codex/2026-10-13/referenced-chatgpt-conversation-this-is-an-3/work/kurdish-audit-evidence/render_test.dart)

The temporary tests mount real existing widgets but replace network/storage/native health boundaries with test doubles; no actual Health permissions are exercised. The render harness uses explicit RTL and a light theme, not the complete application's routing wrapper. Any additional font registrations are test-only; no fonts/themes in BNYAD were edited.

Run the two test files with the repository's Flutter SDK from the main repository, using Flutter test with --no-pub and the absolute evidence-file paths. The standalone AST scanner uses the Flutter tools package configuration for analyzer. The scripts contain local evidence-output paths; adjust those paths if another developer runs them elsewhere.

Evidence images and scripts are local artifacts, not uploaded or pushed. Main/backend source remains at the verified commits.

## Remaining manual verification before claiming complete support

1. Unblocked Safari/Flutter Web walkthrough in Sorani, including actual small/large browser widths, keyboard open, scrolling, all tabs and language changes while navigating.
2. Actual bundled/platform font fallback for buttons/dropdowns and narrow auth layouts; screen readers, focus/reading order, tooltips, back controls and accessibility text sizes.
3. Dark-mode visual review of every primary screen. Existing widget tests cover activity/meal cards, not the entire app's dark UI.
4. All guest/login/registration/OTP errors, timeout/loading/resend cases, localized keyboard digits and full-name/auth accessibility labels using an isolated test environment.
5. Native iPhone/Samsung permission prompts, Health rationale, permissions unavailable/denied/empty/error states, real step updates and reminder delivery. Earlier user-confirmed real steps are not a new Sorani localization test.
6. Native notification channel/settings text, scheduled reminders after language switching and after reboot; avoid sending real-user notifications.
7. Barcode camera denied/blocked/not-found/malformed/offline/success/manual-entry sheets with fictional products; store product-price formatting, purchase/restore/cancel/error states through authorized sandbox testing only.
8. Full food catalog/group terminology and all 602+57+21 localized strings reviewed by a native Sorani nutrition-language reviewer.
9. Food portions, supplements, water dialogs, macro validation, long names, large values and numeric/date-unit mixtures throughout, not just sampled renders.
10. External privacy/terms/deletion web pages (settings links at [lib/screens/settings_screen.dart:262](https://github.com/ahmadosmanr3-hue/bnyad/blob/481a00aa04cb8c465a0985bd2c551691d722bd99/lib/screens/settings_screen.dart#L262), line 283 and line 304) were not opened. Their own Sorani content is UNVERIFIED; do not assume Flutter language applies to them.
11. Live AI Sorani fluency/safety only after separate credential/configuration approval. Do not enable Gemini as part of localization repair.
12. Backend dynamic content in a safe approved test environment; never modify production user data to validate translations.

## Prioritized work after approval

### Priority 1 — correct meaning and usable input

- Implement real application/framework locale handling and Sorani date/picker/accessibility coverage (L03).
- Normalize localized digits/decimal separators consistently, preserving existing authentication and nutrition validation; add explicit localized invalid-input feedback (L04).
- Isolate numeric ranges, ratios, phone prefixes, times and units in RTL; preserve values and chart chronology (L05).

### Priority 2 — remove visible gaps and misleading copy

- Add the missing “or” key and translate hardcoded English captions/tooltips/conditional messages/test-notification text; add lookup-call-site coverage (L01/L02).
- Correct daily-versus-weekly premium promises and platform-specific renewal text, without changing subscriptions/features (L08).
- Localize native camera/photo purpose strings, Android channel descriptions and Health rationale selection/direction; verify actual system limitations (L07).
- Reschedule appropriate local reminders when language changes; design localized admin-notification content, not automatic translation of arbitrary user text (L07).
- Reproduce narrow authentication layout with real fonts and repair only confirmed constraints; fix chart border painting independently (L09/L10).
- Consolidate ckb/ku handling without breaking saved ku records (L06).

### Priority 3 — language polish and exhaustive acceptance

- Native-reviewed glossary and corrected category/health/disclaimer wording (L08).
- Safe catalog-backed relocalization policy for historic/dynamic records; preserve user/brand text.
- Expand tests beyond matching dictionary keys: actual lookups, placeholder multiplicity/interpolation, every input digit script, canonical ckb entry points, notifications after switching, bidi numeric order, accessibility and approved-font screenshots.
- Complete the manual matrix, including device/native/provider states, before marking any screen fully certified.

## Approval boundary

No fixes have been implemented. Review this report and approve the desired repair scope first. The original UI/design, functional logic and verified Git revisions remain unchanged. GitHub commits/pushes belong to the later approved implementation phase, not this read-only audit.

