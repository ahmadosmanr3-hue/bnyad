# BNYAD food catalog and favorites release report

Date: 30 October 2026 (Asia/Baghdad). Submitted release: **1.0.5 (21)**. Store-facing name remains **BNYAD: Calorie & Macro Tracker**.

## Delivery status

- Flutter source: `ebd695b21d880d1e57c52afe27cecadfcc8088d7` (includes `39977d7ebbcd3b584b2a61772950b5e8c008f88e` and `5a0b59ccbc1a6337ebac614300cce4994221aff6`).
- Backend source: `bfdb6d6f62a8992f063a6807c85ad4280843b5a9` (includes initial implementation `edc7a4879afd29a1c47130b4a1970bf59831096b`).
- Both repositories use `codex/bnyad-production-repair-2026-10-25`; pushes verified against GitHub. This is the active production-repair branch, newer than the original stability branch. No reset or force push.
- Backend deployed to the existing `nutrify-api` project: `dpl_AQK4c7XXvAniih5zU1WUwu5jD9Zm`, READY, alias `https://nutrify-api-lovat.vercel.app`.
- Production migration committed successfully; reviewed insert-only import confirmed **829 inserted records**. No historical meal records, profiles, subscriptions, promotional grants or nutrition goals were rewritten.
- Corrected iOS build 21 distribution IPA exported, validated and uploaded successfully after the owner renewed the existing Xcode account. The owner completed Apple’s export declaration; build 21 was selected and submitted. App Store Connect confirms **Waiting for Review** for **1.0.5 (21)**. Submission ID: `bf0ef3b9-fc52-4bc8-acd0-ba5700929d80`. Automatic release after approval is preserved. No replacement certificate was created.
- Corrected Android build 21 signed AAB passed bundle/signature/certificate checks and was saved and submitted to the existing Google Play production track at 100% rollout. Google Play visibly confirms **Changes in review**, with build 21 and managed publishing off; quick checks continue as part of that review request. Build 20 is superseded.
- Complete BNYAD Dev 1.0.5 installed and launched on the connected iPhone using the isolated authenticated local backend and simulated AI. Production and Health Test identifiers were preserved. The user replied positively. The isolated backend recorded four authenticated favorite PUT requests returning 200; the test database contains one canonical-food row at version 4, inactive after removal, with zero duplicate keys. Exact restart/health checklist items were not separately confirmed one by one.
- Samsung was not connected during this task, so no new physical Android test is claimed.

Uploaded/submitted does not mean publicly available. The release-code commit is listed above; this report can be delivered in a subsequent documentation-only commit. Both submitted store updates use corrected build 21. Intermediate build 20 is not the submitted iOS binary and was superseded on Google Play.

## 1. Confirmed favorites root causes

`lib/screens/food_log_screen.dart` always rendered `Icons.star_outline`, created a fresh timestamp ID for every save, and always showed a saved message. Repeated saves were therefore treated as new templates. Food-search and favorites sheets read a passed AppState without subscribing to its changes. `AppState.addFavorite` deduplicated only the generated template ID and notified after disk I/O. There was no server favorites table or favorites endpoint: local-only preferences could not reliably synchronize devices.

## 2. Implemented repair

- Reusable `FoodFavoriteButton`: outlined/filled highlighted stars, immediate state subscription, normal accessible icon-button targets, localized failure messages.
- Stable canonical food IDs for all views and serving variants, preserving old catalog identifiers. Original local favorites are backed up before import; canonical duplicates consolidate without losing unrelated meal logs.
- `FavoritesController`: one optimistic desired state and worker per food; coalesces rapid taps; handles queued changes during a request; per-food versions and account revisions reject stale results; account epochs discard responses after logout/account changes.
- One reconciliation read after a failed/ambiguous write; no blind write retry. A lost successful response is recognized, while a rejected change restores the server state and displays an error. Offline failures do not silently pretend that a cloud write succeeded.
- Bulk account favorites snapshots, short read/write rate limits, no per-row favorite requests. Refresh on account data refresh/resume and entry to food search; scoped local cache supports restart. Other devices receive current server state on refresh/resume. Disk caching now persists only acknowledged server state, never an unconfirmed optimistic intent.
- New authenticated `/api/favorites` GET/PUT/POST. Bearer token determines the user; body user IDs are ignored. A database unique index covers user plus canonical food ID, with serialized user transactions, CAS versions, mutation replay records, and removal tombstones. Delayed imports cannot resurrect removed favorites.
- Favorites retain selected nutrition/portion snapshots and correct g/mL units. Current localized catalog names are used when available. Saved historical food logs remain snapshots.
- Account deletion cascades through favorites, synchronization state, replay records and any duplicate archives. The public privacy policy now explicitly describes favorite synchronization.

## 3. Favorites verification

Before: the star stayed outlined; repeated timestamp saves could duplicate local entries; no server/device synchronization existed.

After, automated tests pass for immediate first-tap fill, second-tap removal, ten rapid taps, changes during an in-flight write, no duplicate rows, lost-response reconciliation, failure rollback, restart/client reload, stale-device conflicts, account-switch response guards, independent users and late-import tombstones. Authenticated route tests use actual disposable PostgreSQL with real sessions. Unauthorized requests receive 401.

Eight committed golden screenshots cover list/detail stars in Sorani at 320px and 1024px, Arabic dark mode at 390px, and English at 430px. Widget tests assert actual selected-star state, navigation consistency, readable food detail and absence of layout exceptions. They also test localized decimal input converting 0.25L to 250mL. These are rendered widget tests, not a claim of two physical-device cloud synchronization testing.

## 4. Catalog counts and organization

Before: 605 bundled records, 576 known canonical IDs, 18 flat categories; the production food table contained zero records.

After: **829 records / 800 canonical foods**, comprising 605 preserved legacy records, 202 USDA reference foods and 22 modeled recipes. There are **7 top-level categories and 42 populated subcategories**; none are empty headings.

Roots: Everyday foods; Kurdish and regional; Fast food; Café; Sweets and desserts; Snacks; Drinks. Subcategories cover rice/grains, bread, poultry/meat, seafood, eggs, dairy, fruits, vegetables, legumes, regional meals/soups/rice, burgers, shawarma/wraps, pizza, fried chicken, sides/dips, coffee/tea, milkshakes/smoothies, cookies/cakes/pastries/chocolate/ice cream, nuts/dried fruit/popcorn and drinks.

Representative additions: weighed/reference milk varieties, egg preparations, rice and noodles, fruits, vegetables, legumes, nuts, cheese, fish, bread and desserts; Americano, cappuccino, latte, iced latte, mocha, caramel macchiato, frappé, hot chocolate, milk chai and yogurt smoothies. Nine modeled milkshakes include vanilla, chocolate, strawberry, cookies-and-cream/Oreo-style, banana, mango, peanut butter, caramel and coffee.

## 5. Nutrition sources and limitations

USDA FoodData Central SR Legacy bulk CSV release: https://fdc.nal.usda.gov/download-datasets/ . Data licensing/attribution: https://fdc.nal.usda.gov/api-guide/ . The selected USDA subset is public-domain/CC0; each entry retains FDC ID, original description, source nutrients and portion evidence. No new USDA API credential, paid API or redistributed Open Food Facts database was required.

The existing 605 records did not have sufficient provenance to claim independent verification; they are labeled legacy estimates without changing their values. USDA entries are generic references, not exact restaurant/manufacturer nutrition. The 22 recipes are explicit estimates calculated from weighed USDA ingredients and modeled finished yields. Ice, blending, cooking, restaurant recipes and portions vary. Oreo-style naming does not claim an exact branded product value. Missing micronutrients are not invented. Manual native-speaker review can still improve localized food wording.

The deterministic builder and reviewed source facts are in backend `data/catalog/` and `scripts/build-food-catalog.py`. Flutter includes the same `assets/catalog/catalog.json` as an offline fallback. Existing AI validation's separate reference dataset was not replaced.

## 6. Serving units, localization and browsing

USDA per-100g facts convert to per-100mL only where an explicit mass for a US-fluid-ounce portion supports a density calculation. Conversion evidence and grams/mL are retained. Whole milk uses 30.5g per US fl oz, not an assumed density of 1. One US fl oz is 29.5735295625mL; one liter is exactly 1000mL. Liquids without reliable conversion remain mass based. Modeled recipe volumes are labeled estimates. Legacy ambiguous liquids are not silently relabeled.

The UI offers known source portions, quantity sliders and direct numeric input, including mL/L selection and Arabic/Sorani digits/decimals. Favorites and new logs preserve the actual base unit; old logs keep their original units and totals. Existing piece/bowl recipes and preparation choices remain supported.

Browsing retains BNYAD branding and components, with root/subcategory navigation, prominent favorites/recents, three-language names and synonyms, ranked search, nutrition-basis labels, provenance/estimate explanations, virtualized result rows and loading/empty states. Existing preparation families stay grouped. A live-browser check caught and repaired a fallback that re-added hidden preparation variants; an additional regression test prevents this. Disabled preparation options are also omitted while other cooking choices remain accessible. Recent foods currently derive from today's loaded food logs.

## 7. Dynamic catalog and admin

`/api/catalog` exposes only public nutrition data, with revisioned ETags, conditional 304 responses and a short cache. Compatible clients load a bundled/cached catalog first, then download current content. Future food additions/corrections do not require another mobile release solely for data. Older published clients retain their existing bundled catalog until updated.

The existing authenticated admin gains Food catalog: search/paginated management, add/edit nutrition, immutable IDs, localized names, category/subcategory management, source/synonym/portion JSON, duplicate-name warnings, optimistic revision checks, audit records and safe disabling. Edits do not recalculate historical logs. Initial import is authenticated, reviewed, insert-only and checksum-idempotent; reruns preserve existing/admin-edited/disabled food records. There is no public seed endpoint or hard-delete food action.

## 8. Database safety and rollback

Migration: backend `db/20261030_food_catalog_favorites.sql`. Explicitly applied to the previously verified existing production Neon project/branch/database, with transaction/advisory locks and statement/lock timeouts. It adds metadata columns, category/state/import/audit tables and favorite/version/replay/archive tables. Every consolidated duplicate is archived in full before deletion; current production had no server favorite duplicates. An ownership FK preserves deletion semantics for archives. The old user/log/subscription APIs remain compatible.

Repeat migration, repeat import, concurrent mutations, uniqueness, archives, account deletion and admin-edit conflict tests ran on a new disposable loopback-only PostgreSQL database. Production verification retained the pre-migration historical-log count. No real-user records were used for local tests.

Rollback: promote the prior known-good Vercel deployment; retain additive schema and user data. Correct an invalid catalog edit from its audit snapshot using the current revision, or disable it. Never drop favorites or reset user records to roll back code. Original mobile data caches remain backed up and canonical imports never overwrite newer server tombstones.

No new environment variables, paid dependencies or credentials are needed. Local iPhone helpers now optionally apply this schema/import and allow only the existing authenticated favorites and public catalog endpoints on the restricted private-LAN server; admin remains inaccessible over that LAN listener. Gemini development allowance remains exhausted/unchanged and mock-only during this task.

## 9. Test and build evidence

- Flutter format: applied to modified Dart files.
- Flutter analysis: **No issues found**.
- Complete Flutter suite: **450 passed**.
- Backend automated suite: **180 passed**.
- Backend TypeScript checks and optimized Next.js build: passed.
- Disposable PostgreSQL integration: passed migration/import reruns, 829 records, canonical alias import, ten concurrent writes, mutation replay, two-user isolation, normal bearer authentication, CAS admin edits, audit/disable behavior and deletion cascades.
- Corrected iOS distribution release: 1.0.5 (21), `com.nutrify.bnyad`. Exported distribution IPA verified, HealthKit true, debugger entitlement false, APNs production entitlement retained, no development markers, public mobile subscription configuration present.
- Corrected signed Android release: 1.0.5 (21), `com.bnyad.app`. Bundletool validation, JAR signature and existing Google upload-certificate fingerprint match passed. Camera and Health Connect permissions, catalog asset and public mobile subscription configuration verified.
- Corrected build-21 iOS IPA SHA-256: `84526defe8efab94b2f92b6587b4a4cb3a6f77b9f72304c6f6b4be832d82129e`.
- Android AAB SHA-256: `ae37e7f98e2f0a7545fa585eb5795bac7f8a8c424f9db0cb2a492c92f130838f`.
- Real iPhone: complete isolated development build installed and launched, preserving production and Health Test apps. No connected Samsung was available.

Existing authentication, Premium/gifts, startup guards, AI contract/safety/quota handling, barcode/camera, native-health and localization regression suites were run. No new paid Gemini generation, real purchase, production push campaign or real-user-data testing was performed. Existing production AI configuration, nine-request daily quota and monthly budget were not changed.

## 10. Store notes and remaining verification

Release notes in English, Arabic and Sorani are in `release-notes/1.0.5.md`. The existing store name, application identifiers and signing credentials are preserved. Private signing/configuration files and local databases are excluded from Git.

At task start Apple publicly showed 1.0.4, while Google Play still showed version 19 (1.0.4) in review. This update includes that prior startup hotfix. Current console evidence: Google Play **21 (1.0.5)** shows **Changes in review**, managed publishing off, full rollout selected; compatibility checks report zero lost devices (12,509 phones and 6,823 tablets remain supported). Intermediate build 20 was superseded. Apple **1.0.5 (21)** shows **Waiting for Review**, with automatic release after approval and immediate release to all users preserved. The owner renewed Xcode's existing account, reauthenticated App Store Connect and completed the build-21 export declaration. No replacement signing certificate was generated. English, Arabic and Sorani release notes were entered in the existing default store localizations (combined multilingual notes, not new independent store-listing locales). Neither store submission is represented as already approved or publicly live.


Nonblocking existing build warnings: iOS placeholder launch-image validation, plugins not yet supporting Swift Package Manager, and upcoming Flutter AGP/Kotlin minimum-version changes. No dependency upgrade was mixed into this food/favorites update. More regional recipe verification, native-speaker wording review, and physical Android verification remain useful follow-ups; none are represented as already completed.

## Store submission receipts and release behavior

Apple: existing app ID `6781387722`, **1.0.5 (21)**, **Waiting for Review**, submission `bf0ef3b9-fc52-4bc8-acd0-ba5700929d80`. Existing private reviewer credentials were preserved; reviewer notes reference build 21. The owner saved export compliance. Automatic release on approval and release to all users immediately remain selected. Do not resubmit intermediate build 20.

Google Play: existing `com.bnyad.app` production track, **21 (1.0.5)**, **Changes in review**, 100% rollout, managed publishing off. The corrected bundle supersedes build 20. Google’s automated checks remain part of its review workflow. No approval/public availability is claimed.

Both receipts were saved privately on the development Mac; screenshots with private review credentials were not committed. The signed iOS IPA is `build/ios/ipa21-verified/BNYAD.ipa`, archive `build/ios/archive/Runner.xcarchive`; Android bundle is `build/app/outputs/bundle/release/app-release.aab`. Their validated SHA-256 values are listed above. Keep team `632WWWM8AH`, bundle `com.nutrify.bnyad`, HealthKit, production APNs and existing Android upload signing. Signing/private config, databases and artifacts are excluded from Git.

No further owner action is currently required for submission. Apple/Google may request additional review information; review duration and approval are controlled by the stores. More regional recipe verification, native-speaker wording review, and a physical Samsung regression check remain useful follow-ups, with the physical-device limits explicitly stated above.

The localhost demo preview remains available at `http://127.0.0.1:8765/` while its development server runs. It uses fictional data and simulated AI. The native iPhone local backend remains authenticated and mock-only, preserving the exhausted Gemini development ledger.
