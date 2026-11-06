# BNYAD Food System Phase 2 — implementation report

Date: November 6, 2026. Mobile version: **1.0.7 (23)**, prepared but NOT submitted.

## Changes beyond the food additions

- **Text-only food browser:** reusable result cards with food name, category/source qualifier, reference nutrition, favorite star and a large Choose portion action. No thumbnails in ordinary food results. Existing preparation groups and categories remain navigable; virtualized lists remain in use.
- **Three-language search:** English, Arabic and Sorani names/aliases; Arabic marks/tatweel and Arabic/Persian digit normalization. Search text now survives returning from details, so the field matches the filtered list. RTL nutrition fragments are isolated to retain number/unit order.
- **Favorites presentation:** the same existing account-scoped, idempotent favorites controller supplies browser/detail stars. Tests verify immediate state changes and removal. Existing failure/restart/account-switch/rapid-tap tests remain passing. No new subscription or authentication bypass was added.
- **Recent foods:** a bounded list of 30 canonical IDs, stored separately per backend/account, updated after successful logging, deduplicated and preserved across restart. Loading/writing cannot block core authentication or logging. An initialization race was covered by a regression test.
- **Measured portions:** food-specific gram/mL input for defined spoons, small/medium/large plates, slices/whole-pizza boxes, cans/bottles/cups; liters convert exactly to mL. Users supply measured weights/label volumes. No universal spoon, plate, pizza slice or liquid-density assumptions. Existing documented catalog portions remain available. Dialog controllers now follow widget lifetime, fixing a close-animation disposal error found in tests.
- **Optional two-photo food scan:** required top photo plus optional side view, review/retake/remove before submission, bounded combined image size and clear Google-sharing/estimate explanation. Optional measured capacity/depth/weighed-food inputs. Backend sends both views as one meal and explicitly instructs against double counting. Existing single-photo clients remain supported.
- **Scan corrections:** users can select a gram-based catalog identity and adjust quantities before saving; nutrients/micros scale from that catalog reference. Duplicate corrected detections can merge within the supported portion bound. Disabled catalog foods and unsupported liquid-to-mass guesses are excluded. These are user-reviewed estimates, not exact photographic measurements.
- **Admin bulk importer:** CSV/JSON, rights/source/unit/duplicate/nutrient checks, dry run, checksum and revision confirmation, insert-only transactions, audit, idempotent replay, progress/conflicts and downloadable revision-safe disable remediation. Private rights evidence is excluded from public catalog responses. Admin credentials remain in memory.
- **Development tooling:** Android preview uses Flutter to bootstrap its ignored wrapper and correct app version; sanitized fail-closed preview setup diagnostics. No changes to the dashboard/navigation design, calorie goals, subscriptions, health formulas or production authentication.

## Catalog and duplicate handling

Production before: 940 records / revision 2. After reviewed import: **942 records / revision 3**.

Added only FDC 174807 (Chinese-restaurant egg-drop soup reference) and FDC 171257 (cultured sour cream), independently sourced USDA CC0 records. These are not certified local-recipe equivalents. Two guarded Brown Rice/Rye Bread search-alias improvements were applied. No nutrition values or existing food IDs were replaced.

The bundled identity audit contains 913 canonical identities and 29 existing serving-alias records. Canonical aliases are collapsed in browsing while their IDs/history remain intact. Eleven same-English-name review groups remain flagged; name equality alone is not sufficient to merge recipes, sources or preparation methods. The UI shows 726 browse roots because preparation groups and serving aliases are intentionally grouped; this is not a loss of catalog records.

All 1,340 research observations remain saved locally. **350 candidates are NOT imported**: their rights/source review is unresolved. Four local blocked draft batches preserve source evidence and original reference quantities; 331 also need category assignment. Observed household weights may have been account-specific and are not approved conversions. **783 unresolved contexts** remain in the original review queue. The 34 energy flags retain their original findings (18 numerical USDA corroborations, 16 unexplained), without arbitrary nutrient edits. No raw uncleared catalog or source photos were published to GitHub.

## Verification completed

- Flutter analysis: **No issues**.
- Full Flutter suite: **467 passed** (including existing authentication, subscription, health, localization and favorites regressions).
- Backend typecheck: passed; **192 backend tests passed**; Next.js production build passed.
- Actual dedicated loopback PostgreSQL integration: authentication, no-write preview, stale revision, deliberately injected late failure/atomic rollback, insert-only apply, idempotency, revision-safe disable, guarded aliases/metadata preservation, unchanged fixture historical log/favorite. Existing schemas were applied ONLY to that disposable local database.
- One/two-photo widget fixtures: retake/remove, localized measurements, picker failure; no Google IO. Backend multimodal request/measurement/redaction and old one-photo behavior tests passed.
- Portion arithmetic, catalog correction nutrition/micros, invalid portions/volume guessing, recent-account isolation/initialization/restart, narrow RTL accessibility tests passed.
- Golden screenshots: English 430 light, Arabic 390 dark, Sorani 320 light and 1024 dark; details, stars and volume arithmetic verified. No text scaling workaround was used to hide layout constraints.
- Pixel 8 emulator: latest full offline Dev app installed/launched; food browser/details/favorite interaction and one-favorite persistence after restart verified. Fictional fixture data only; no production account/API access.
- iPhone 18 Pro simulator: latest ad-hoc-signed full Dev preview installed/launched; food browser, details, measured serving and favorite filter verified. An unsigned simulator build could not use secure health preferences; using normal ad-hoc signing resolved it without weakening storage or HealthKit guards.

- iPad Pro 13-inch simulator: full Dev preview launched; tablet food browser and visible favorite/portion controls inspected, with screenshot saved.

Screenshots are under artifacts/phase2-screenshots; golden images under test/goldens. Simulator-only checks do not establish physical camera/HealthKit accuracy. Physical-device login, real steps, purchases/restores and real notifications were not repeated for this phase. Existing automated regression tests pass, but that is not a new physical-device end-to-end claim.

## Backend production rollout

Deployed tested runtime commit **61649220e410557e28c86047799df745437ad96e** to existing nutrify-api project/team, deployment **dpl_7sVdFhvH8Knh71NqksNJkqhN3R4C**, READY:
https://nutrify-api-lovat.vercel.app/

Authenticated reviewed import: **2 additions, 0 category changes, 2 alias updates, 0 conflicts**. Snapshot comparison confirms all prior IDs and nutrition preserved. Public schema remains version 1, conditional GET returns 304, and unauthenticated admin/catalog-bulk/AI requests return 401. PRODUCTION_VERIFICATION.json records the comparison. No migration was required/applied in production. No Gemini request, AI enablement, model/quota/budget change, purchase or notification send was made.

Rollback runtime target: previous deployment dpl_FyoB3Mm493JvPLZqUqJGhamesFFq. Data retraction uses audited revision-controlled disable, never food/log deletion. Existing aliases have before/after audit entries for reviewed reversal.

## Release packages

Android signed AAB: build/app/outputs/bundle/release/app-release.aab. Signature verified and matches the existing private upload keystore. SHA-256: 225a962767d9824ee144623fe8c4a4e4ae3fbe136ee4ffd28444d0f7d7148a0f.

iOS exported IPA: build/ios/ipa/BNYAD.ipa; archive: build/ios/archive/Runner.xcarchive. Bundle com.nutrify.bnyad, version 1.0.7/build 23, no offline/local-backend flags. SHA-256: f486c055f8d4a1f2a2fcfe87eb80efb4abafe8587a5d70e4aafd410af35544dc. Existing Xcode account needed reauthentication; export subsequently succeeded. Existing launch-image placeholder warning and plugin Swift Package Manager adoption warnings remain; they did not prevent archive/export and no branding assets were replaced.

Production IDs/signing preserved. Build artifacts, local config, Firebase files and signing secrets are ignored and are not committed. No dependency change or new server environment variable is required. Android uses JDK21; the Mac's JDK25 was incompatible with the existing Gradle version.

## Remaining before mobile submission

1. Personally review the new browsing/portion/photo-review wording and layouts on physical phones and a tablet.
2. Perform measured real-food single/two-photo accuracy testing only under separately approved live Gemini allowance; no new live accuracy claim is made here.
3. Recheck physical camera/gallery permissions, real HealthKit/Health Connect data, notifications, login/session and purchase/restore on the final release candidate.
4. Review the inherited launch-image warning before store submission.
5. Clear licenses, category assignments, preparation/source conflicts and serving evidence before importing any of the 350 candidates; resolve the 783-context queue independently.
6. Obtain the user's **final approval before any App Store Connect or Google Play upload/submission**. Nothing from this phase was submitted.

## GitHub delivery

Both repositories use branch **codex/bnyad-food-system-phase-2**. Backend runtime commit is identified above; final handoff/tooling and Flutter source commits are recorded in DELIVERY.md after push verification. The next developer should pull this branch in BOTH official repositories, read docs/food-system-phase-2/OPERATIONS.md, and use private signing/config inputs. Existing unrelated working trees and their uncommitted changes were preserved.
