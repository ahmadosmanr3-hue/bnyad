# BNYAD scanner result repair — 18 November 2026

## Root cause

The screenshots show the existing `recognitionVersion: 2` **needs-review** branch. The backend intentionally returns `components: []` and no invented macros when a dish/preparation cannot be safely resolved against its conservative **119-ingredient** AI subset. The complete public catalog contains **942 foods**. Regional prepared dishes frequently require an explicit catalog choice because there is no verified ingredient recipe to decompose them.

Flutter rendered candidate names as non-interactive ListTiles in a large inline card. The only escape was a generic search. The old correction flow excluded volume-based foods, could only replace a whole result or an existing component, and did not provide add/remove controls. Matched result previews also rounded individual component nutrients before summing. The backend was not returning a hidden ingredient list that Flutter had failed to render.

## Changes

- A dedicated, compact scan-review route replaces the giant inline result card. It has an editable meal title, actionable candidate choices, searchable catalog preparations, component cards, calories/protein/carbs/fat, a persistent total and Confirm and Log footer. Longer safety explanations expand on demand.
- Food identity, amount and preparation must be reviewed. Unknown rows remain unresolved until explicitly replaced or removed. A new identity requires a portion; no default 100 g is presented as an AI estimate. Explicitly supplied measured weight is retained for a whole gram-based dish.
- Add, remove or replace components without another scan. The existing portion editor supports manual g/mL, quantity buttons, catalog servings, measured spoons/bowls/plates, pieces/pizza and drink volumes. Nutrition previews retain full precision until display.
- Whole-dish mode and individual-component mode are mutually exclusive. Prepared catalog dishes cannot be mixed into an ingredient breakdown. No verified ingredient recipes currently exist in this catalog, so none is fabricated. Whole dishes can be portion-adjusted; independent sides can be logged separately or built from confirmed individual ingredients.
- English, Arabic and Sorani names/aliases drive catalog searches. Regional search expansions include biryani, dolma/yaprax, shawarma, kebab/tikka, soups and stews. Suggestions are never silently substituted with plain rice. Numeric fragments keep explicit LTR direction within RTL screens.
- New `POST /api/logs/scan` authenticates normally and recalculates all saved nutrition from current server catalog records. It rejects missing confirmation, unavailable/disabled/duplicate canonical foods, incorrect units, invalid/oversized quantities, whole-dish/component double-counting, changed revisions and altered totals. No mass/volume density is inferred.
- A transaction saves each confirmed component once as an ordinary food-log row in its real reference unit; mixed g/mL quantities are never added into a fictitious meal weight. The app uses authoritative returned rows. Account-scoped retry receipts and disabled in-flight controls protect against duplicate submissions, including lost responses/concurrent requests. Legacy log requests retain their contract.
- Session-owner checks protect asynchronous results/saves. Failure messages stay visible beside the save action, edits remain available for correction, and no automatic scan/save retry is added.
- Backend changes are delivered to **bnyad-backend**, the authoritative deployment repository. The older `vercel-api/` snapshot in the Flutter repository is explicitly marked as a legacy copy; do not deploy it.

Dashboard, navigation, theme, calorie targets, HealthKit/Health Connect, purchase/consent/AI quota logic and fridge scanning were not redesigned. There is no new dependency, environment variable, migration, production seed or rewrite of existing food/history records.

## Verified checks

- PASS: Flutter analysis; **521** automated Flutter tests, including 29 new scanner model/widget cases and 24 locale/theme/width combinations (320/390/430/1024 logical pixels).
- PASS: **232** backend tests, TypeScript check and production Next.js build.
- PASS: real isolated loopback PostgreSQL test using a fictional account and normal bearer session: concurrent duplicate submission, rice/meat, biryani, dolma, shawarma, pomegranate, mixed g/mL logging, invalid totals/confirmation, read after save, unchanged historical fixture, unchanged other accounts and catalog. The new test account is cleaned up. No migrations or external provider access.
- PASS: Android Pixel emulator and Android tablet-size emulator run the actual scanner → fixture image → authenticated mock response → result editor → saved diary flow. Cases include single food, multiple components, Kurdish rice/meat, biryani, dolma, drink, three candidates, unknown food and missing/inconsistent provider nutrition. Results are recalculated from the catalog and saved values are checked. Session, language and saved logs survive recreated app state.
- PASS: iPhone 18 Pro simulator repeats the same full flow, locale/theme and photo-review checks.
- PASS: both native runs exercise single/side photo preview, retake, removal and cancel in all three languages and themes. The picker uses a licensed fixture image; repeated fixture angles test controls only, not recognition accuracy or hardware permission prompts.
- PASS: Android native correction checks cover replacing, adding/removing, invalid quantities, quantity +/- buttons, canonical duplicate rejection, rapid save taps and visible failure states. The small-iPhone simulator passes the same correction, quantity, duplicate and rapid-save checks, including a visible error message.

## Backend rollout

Production deployment: `dpl_H8gU3cazoVogFTaY65QzeLkt1wNx`, tested source commit `85ea8e282bbb5b90cada194e99ff3b1679301958` on `codex/bnyad-food-system-phase-2`.

Backend repository head: `3b1f37543174baf78232f8eb3427ec9da4d542ac`; changes after the runtime commit only strengthen local verification and document rollout. Mobile build source: `4294adefd0a512cf26872780454bbf4540b62184`.

Existing endpoint: https://nutrify-api-lovat.vercel.app/api . Deployment is READY and the production alias points to it. Read-only checks pass: `/up` 200; `/catalog` 200; anonymous `/auth/me`, `/logs`, `/logs/scan` and `/ai/generate` 401; development readiness 404. The full public catalog is byte-for-byte equivalent as parsed JSON before/after: **942 foods, revision 3**. No production test meal or account was created. Historical preservation is exercised on local fixtures; private production histories were not downloaded.

Rollback baseline: `dpl_DTKNnj3i1oCnJx2JTpvVJJbjSfyt`. No migration needs reversing. Old clients remain compatible; the old result UI requires a mobile update to change.

## Screenshots

Actual native UI with explicitly simulated recognition data:

- [Sorani component editor](screenshots/android-sorani-components.png)
- [Sorani three-candidate selection](screenshots/android-sorani-candidates.png)
- [Arabic iOS editor](screenshots/ios-arabic-components.png)
- [English iOS pomegranate](screenshots/ios-english-pomegranate.png)
- [Android tablet layout](screenshots/android-tablet-sorani.png)
- [Small iPhone corrected components](screenshots/ios-small-sorani-corrected.png)
- [Small iPhone visible save error](screenshots/ios-small-sorani-save-error.png)

All **91** captured native screenshots remain in ignored `build/scanner-result-evidence/`. No user photos or account credentials are included.

## Calculation evidence

[CALCULATION_CHECKS.json](CALCULATION_CHECKS.json) records unrounded catalog calculations, including 150 g pomegranate = 124.5 kcal; 200 g rice plus 100 g chicken = 425 kcal; 200 g chicken biryani = 396 kcal; and 250 g dolma = 375 kcal. These are catalog estimates, not newly measured nutritional truth or live recognition results.

## Release and limitations

Mobile version is **1.0.9 (25)**, using the existing production identifiers/signing. Both signed release packages are validated. Android uses `com.bnyad.app`, version code 25, non-debuggable release settings and the existing verified upload certificate. The exported iOS IPA uses `com.nutrify.bnyad`, team `632WWWM8AH`, no debug entitlement, HealthKit and production APNs; camera/health explanations and production ATS remain present. Exact source/artifact hashes are in DELIVERY.json. On **19 November 2026**, the authorized follow-up release submitted both packages to the existing production listings: Google Play **Changes in review**, Apple **Waiting for Review**. Both retain automatic release after approval. Publication is not yet confirmed. The published baseline inspected before submission was 1.0.8 (Android version code 24). See [final release verification](release-1.0.9/RELEASE_STATUS.md).

No live Gemini request was made: recognition accuracy and the benefit of a second angle remain **unverified**. This fix makes uncertain results useful and safely editable; it does not claim better model accuracy. Real device camera/health, OTP, push and purchase/restore were not repeated on physical hardware in this task. Existing platform configuration is preserved. iOS remains officially iPhone-only; wider widget tests do not enable full iPad support. An unsaved scan is kept while navigating back to its review but is not persisted across an app termination; confirmed diary entries persist normally.

The next developer can pull both existing branches and inspect the saved submission records. Do not submit duplicate build 25 packages or deploy the legacy backend copy in the Flutter repository. Production AI configuration, billing and spending limits remain unchanged.
