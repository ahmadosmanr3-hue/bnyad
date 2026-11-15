# BNYAD measurement and AI improvements

Report: 2026-11-16. Tests: 2026-11-15–16. Branch in both repositories: `codex/bnyad-food-system-phase-2`.

Status: implementation complete and offline/native UI checks passed. Live recognition accuracy remains unverified. No store submission, production deployment, database migration or live Gemini request was performed. Final source commit identifiers are recorded in `docs/measurement-ai/DELIVERY.md`.

## Original problems and changes

The old flow split portion presets, a separate measurement dialog, disabled piece/bowl buttons, a 10–1000 slider and another numeric dialog. Several legacy piece/bowl defaults were estimates without an obvious explanation. It also clamped small positive quantities to a gram and could retain piece-mode calculations after a weight edit. New food logs accepted client-supplied totals without authoritative catalog recomputation.

`lib/widgets/portion_editor.dart` replaces those competing controls inside food details only. It provides grams, teaspoons, tablespoons, level/heaped tablespoons, small/medium/large bowls and plates, pieces/slices, whole pizzas and custom servings. Volume-referenced foods provide mL, L, glass, can and bottle, with explicit capacity choices. A quantity field and accessible stepper update the displayed total, calories and every macro. Invalid/negative/nonfinite/excessive values disable saving. A synchronous save guard prevents repeated taps while saving. The original dashboard, navigation, colors, food lists and subscription/authentication architecture are preserved.

Food lists remain text-only. Existing catalog IDs, aliases, favorites, Recent, raw/cooked preparations and historical records are not replaced. Logging uses the original declared nutrient reference amount; there is no universal 100g-per-serving assumption.

## Conversion rules

- `amount = amount-per-unit × quantity × fill-fraction`. Maximum stored total for this new editor is 10000 g or mL; quantities must be finite and positive.
- One L is exactly 1000 mL, **only** for foods whose nutrition reference is volume. No universal density or mL-to-g conversion was added.
- For USDA gram-referenced foods with a documented **1 cup** portion, a level tablespoon can be estimated as that food's cup weight /16, and a teaspoon /48. These are explicitly estimates, rounded to 0.1 g: packing and preparation vary. Raw/cooked foods retain their own distinct reference and portion data. Heaped spoons have no invented multiplier.
- Catalog servings retain their existing weights and `estimated` status. A spoon/bowl/plate/piece/pizza without a documented conversion requires an entered edible weight. A container's label is not proof of its weight.
- Bowl/plate fill scales the entered full-portion mass. For volume-referenced drinks, it scales the entered volume. It never derives density or mass from container size.
- Pizza slices/whole pizzas use the actual food-specific entered or catalog weight; slice counts do not imply an unverified pizza diameter or number of slices.
- Existing bone-in yield factors are unchanged and applied once on the server for newly opted-in catalog logs.

US household ratios follow 16 tablespoons/48 teaspoons per cup; this derived estimate must not be confused with a weighed portion. Direct food-specific weights and package labels take priority.

## Backend authority and compatibility

Backend `lib/portion-nutrition.ts` and `/api/logs` recompute NEW opted-in catalog logs from enabled server catalog records, reference units and current nutrients. Client macro fields cannot override the computed result. Reviewed AI component logs are recomputed component by component; duplicate/unknown/volume-based components and inconsistent total mass are rejected. Mixed mass/volume entries require separate logs.

Legacy installed clients, custom foods, barcode-label entries and historical snapshots retain their existing request contract. Historical records are never rewritten. There is no new migration or production database access in this work. The broader legacy logging contract still accepts old client snapshots for compatibility; this is deliberately separate from the new opt-in calculation path.

## Recognition and photo workflow

The actual recognition constraint was the conservative, small ingredient catalog used by Gemini's existing food schema. It could not safely represent many regional recipes and had no structured uncertain-identification path. This work does **not** claim a larger verified regional ingredient/allergen database or measured improvement in model recognition.

New Flutter scans request `recognitionVersion: 2`. The new food schema adds matched/needs-review status, up to three translated plausible candidates and visible evidence. Unknown recipes or ambiguous biryani/pilaf/dolma/kebab/shawarma should return candidates with **no invented nutrient totals**; the user chooses the actual catalog preparation and weight before logging. Old clients keep their original schema. English, Arabic and Sorani names are validated using existing script checks; no numerical confidence percentages are fabricated.

Instructions distinguish top/side photos of the SAME meal, hidden ingredients and regional preparation differences. User-weighed mass takes priority and is checked against summed component mass; it is also preserved while an uncertain identification awaits manual correction. Oversized corrections are directed to separate measured food logs rather than throwing an uncaught exception. Existing calorie/macro/allergy bounds are unchanged. No retries or paid-model escalation were added. Both images still share the existing combined 1 MiB limit; each image remains JPEG/PNG, metadata is sanitized, native primary picking retains the existing 800×1600/quality-80 bounds and side picking uses 800×1200/quality-70, and no image bytes are stored by the AI endpoint. The existing iOS image picker normalizes orientation when resizing. Image-picking settings were inspected; compression/orientation accuracy across all devices is not certified by mocks.

`meal_photo_review.dart` adds practical focus/orientation/lighting guidance and explains that a side view is another view, not another portion. Review, retake, remove, cancellation and optional measurements remain available.

## Evaluation, model and cost

Backend `evaluation/` contains four openly licensed public photographs: Iraqi biryani, dolma, kebab and pizza, with source/author/license metadata. These support author-labeled identification evaluation, not independent recipe or weighed-portion ground truth. No real paired-view or weighed meal set is available yet. Broader Kurdish/Arabic mixed meals, drinks, fruits, desserts, confusing lookalikes and negative images remain needed.

The offline scorer records identity confusion pairs, mixed-meal accuracy, hallucinated-food counts, portion error, view-level identity rates, latency and cost from saved human-reviewed observations only. Unmatched single/two-view rates are descriptive, not proof of improvement. The scorer cannot turn mocked predictions into accuracy results. Currently there are **zero new live Gemini observations**: identification accuracy, portion error, live latency, single-versus-two-photo gain and actual cost are unverified/null. The earlier exhausted development-request ledger was not changed. Any live evaluation needs a separately approved request allowance.

No model or billing configuration changed. Keep the existing configured model pending an authorized comparison; lower price alone does not establish recognition quality. Google currently lists Gemini 3.5 Flash-Lite Standard at $0.30 input/$2.50 output per million tokens. An illustrative 2000-input/500-output generation is $0.00185, excluding any separately applicable services; actual image tokens vary. Rates must be reconfirmed in deployment configuration, not assumed from older estimates. The existing admission budget, combined nine-request daily limit, consent, Premium and request accounting remain enforced.

Primary references checked 2026-11-15:
- https://ai.google.dev/gemini-api/docs/pricing
- https://ai.google.dev/gemini-api/docs/image-understanding

## Tests, screenshots and scope of evidence

Automated unit/widget tests and native evidence are recorded in `docs/measurement-ai/`. Native tests run the complete existing app with fictional offline API fixtures and network transport blocked; they are not production-server or paid-recognition end-to-end tests. Native photo-review fixtures inject the same licensed image to exercise input mechanics; they do not establish two-angle recognition accuracy or camera hardware quality.

Native keyboard event injection is registered explicitly in the automated portion runner to avoid OS keyboard input racing test-generated edits. This is controlled automated input; native keyboard/permission/picker checks must be reported separately. Simulator camera availability cannot prove a physical camera works.

## Delivery and rollback

No production deployment, migration, purchase, billing change, live Gemini call or mobile-store submission is included. After approval, deploy the backward-compatible backend first, verify authenticated legacy and v2 requests against nonprivate test data, then release the mobile app. Retain the prior known-good Vercel deployment for rollback. If v2 validation fails, disable AI through the existing server control rather than returning mock results to production. No destructive rollback or data migration is needed.

The 350 blocked food candidates and unresolved Juula research remain preserved and are not imported or discarded. No catalog nutrient values were changed in this task.

## Final verification checklist

- PASS: `flutter analyze`, no issues; **492 Flutter unit/widget tests** including conversions, Arabic digits, amounts under 1g, invalid quantities, fill fractions, food-specific spoon estimates, single-save protection, optional Health profile storage failure, auth/consent/Premium/steps/localization regressions.
- PASS: **202 backend tests**, TypeScript checking, Prisma generation and Next.js production build. No database migrations or production data reads/writes were needed for these checks.
- PASS: full existing app native measurement suite and photo-review UI suite on Android API 36 phone, Android 320×640 logical viewport, Android 1024×1366 tablet-sized viewport, iPhone 18 Pro, iPhone 13 mini, and full-width iPad Pro 13-inch simulator test build. English/Arabic/Sorani, RTL, dark/light rendering, spoon/bowl/plate/pizza/volume quantities, immediate calorie updates, invalid inputs and navigation were exercised. Macronutrient arithmetic is additionally checked by Flutter/backend unit tests.
- PASS: **306 native captures** from the six passing runs; selected screenshots and hashes in `docs/measurement-ai/`. Native tests used controlled keyboard event injection to avoid IME races; this is identified in the runner.
- PASS: actual Android camera permission prompt/camera activity launch; native Android system photo-picker input reached review with two selected licensed images. Actual iOS system photo picker accepted its built-in nonprivate lemon image; single/second photo, removal, retake and cancellation were checked through Xcode Device Hub. These manual flows were canceled without live analysis. Native system picker screenshots are evidence of selection/UI behavior, not recognition quality.
- EXPECTED LIMITATION: iOS Simulator requests camera permission but reports **Camera not available**. It stays usable afterward. This does not verify physical iPhone camera capture.
- FIXED: unsigned iOS Simulator preview could fail at optional Health profile storage with a keychain error. Optional-profile restoration now leaves the profile unset instead of blocking the complete offline app. A regression test covers the failure. Health access/errors remain truthful; no fake steps or security downgrade was introduced.
- LIMITATION: the shipping iOS project declares **iPhone only**. The iPad compatibility run passed; a separate simulator-only device-family override verified full-width iPad layout. Production device support was not expanded automatically. Native iPad release support requires separate product/store configuration review.
- NOT CLAIMED: real Gemini accuracy, new live latency/cost measurements, independently weighed portion accuracy, two-angle quality gain, physical-device capture/Health regression on this commit, new real OTP/push/purchase-restore tests against production. Existing automated regressions pass; no production account was used.
- HOLD: app-store release and production backend rollout await approval. Live evaluation needs a separately approved request allowance; the exhausted ledger stays unchanged.

## Reproduce and review

Flutter: `flutter pub get`, `flutter analyze`, `flutter test`. The only added dependency is Flutter SDK `integration_test` in dev dependencies and its locked test dependencies. No new production Flutter dependency was added.

Android native runner: set a compatible JDK (21 was used), `ORG_GRADLE_PROJECT_bnyadLocalBackend=true`, then use `flutter drive --driver=test_driver/measurement_driver.dart --target=integration_test/measurement_native_test.dart -d DEVICE`. This integration-only entry point blocks real network access and uses fictional local fixtures; the flag keeps its application ID separate. Do not use it for store builds.

iOS native runner: use the existing `dev` scheme and explicitly override `FLUTTER_TARGET=integration_test/measurement_native_test.dart` when building the simulator app, because that scheme deliberately pins its default target to `main_development.dart`. Install/launch the simulator app, then connect the driver with its local VM service URL. Do not commit debug service URLs or use this target in release builds. Xcode 27's Device Hub provided native simulator interaction.

Backend: `cd vercel-api && npm ci && npm test && npm run typecheck && npm run build`. No new environment variables, database tables or backend dependency packages are required. New request fields (`recognitionVersion`, `catalog_calculation`, `catalog_components`, `with_bones`) are backward compatible. Keep the existing server-only Gemini key/model/prices, auth, consent, budget and quota configuration; verify published prices before an approved deployment. No key belongs in Flutter.

Git-triggered Vercel deployment remains disabled by the existing `vercel.json`. Deploy the reviewed backend before releasing the mobile changes, smoke-test the new and old request versions, and keep the prior known-good deployment for rollback. Allocate the next unused store version/build only after final release approval; this task did not reuse build 23 for a new store submission.
