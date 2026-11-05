# BNYAD catalog completion — 1.0.6 (22)

Prepared November 4, 2026 (Asia/Baghdad). Existing listing name: **BNYAD: Calorie & Macro Tracker**.

## Delivered content

Production now serves 940 records / 911 canonical foods across seven roots and 53 populated subcategories (60 category records). This adds 111 records to the released 829-record catalog and applies 218 audited category-only corrections. The pizza category has 34 entries: four preserved legacy entries, 18 USDA references and 12 explicit topping-recipe estimates. Drinks include energy drinks, five sports drinks, region-labeled packaged drinks, coffee, tea, smoothies and all nine modeled milkshake flavors. Added dessert references include waffles, pancakes, white vanilla-style cake and caramel, fudge and strawberry sundaes.

The full dataset contains 605 preserved legacy estimates, 255 USDA references, 34 modeled recipes, 45 manufacturer-label beverages and one Japanese MEXT pitaya reference. Country-specific packaged formulas carry their region and provenance; they are not represented as Iraqi product labels. Unknown caffeine, barcode and package-size facts remain unknown. Measured volumes are distinct from verified package sizes. USDA sports-drink mass-to-volume conversion retains the source fluid-ounce weight; 100mL is never universally assumed to equal 100g.

Reclassified examples include pizza previously under regional meals, Big Mac/Quarter Pounder/Whopper under burgers, fried chicken/tenders, hot dogs, sandwiches, regional sweets, chocolate, popcorn, ice cream, dried fruit, milkshakes, coffee, tea, juices, soft drinks, seafood and eggs. Original food IDs, canonical relationships and nutrition values remain intact.

## Production rollout and safety

Backend source: `bf053c9d2099591598698680d912f864f74257a6`.
Vercel project: `nutrify-api` (`prj_UlmfpaZA11IW3KPv6YYAl5lC3qj3`), existing team `team_j2wxP1KPjHVlgRLMlubUTzpT`.
Deployment: `dpl_FyoB3Mm493JvPLZqUqJGhamesFFq`, production **READY**, serving https://nutrify-api-lovat.vercel.app .

Authenticated admin import confirmed 111 insertions. A public before/after comparison confirmed 218 corrected categories, zero changes to all existing nutrition/portion fields, 940 records and 60 categories. Catalog revision is 2 and conditional ETag requests return HTTP 304. Health endpoint returns 200; unauthenticated favorites, admin catalog, profile and AI-generation calls return 401. No runtime error clusters were reported for catalog/admin/favorites routes in the checked 30-minute window.

No production schema migration was needed. Import operations use the existing transaction/advisory lock and checksum ledger. Existing category IDs are changed only when the reviewed canonical ID and old category match; conflicting administrator edits are reported and left untouched. Each correction has before/after audit data. Food nutrition, enabled flags, meal logs, accounts, subscriptions, gifts and health records are not rewritten.

Compatible 1.0.5 clients can fetch the expanded catalog now. Version 1.0.6 bundles the same content for offline use. Restart/reopen food browsing to refresh within the existing cache policy.

Rollback: restore the previous Vercel deployment, restore category IDs selectively through current-revision-checked audited edits, and disable problematic additions using existing admin controls. Preserve historical logs and user data; do not reset the production database.

## Verification

- Flutter analysis: no issues.
- Flutter tests: 450 passed. Updated four list reference screenshots after visually reviewing the intended category/search changes; no dashboard redesign was made.
- Backend: 184 tests passed, typecheck passed, Next.js production build passed.
- Real disposable local PostgreSQL integration passed repeatable import/migrations, category corrections, preservation of custom nutrition, administrator-conflict handling, import idempotence, duplicate archives, concurrent favorites, canonical aliases, user isolation, authentication and deletion cascades. External calls were blocked in that integration test.
- Signed Android release AAB built with Java 21; bundletool and signature verification passed. Manifest: com.bnyad.app, 1.0.6, version code 22, with camera and read-only Health Connect permissions preserved. Upload certificate matches the existing approved fingerprint.
- Signed iOS archive and App Store IPA built/exported successfully. Distribution IPA signature verified: com.nutrify.bnyad, 1.0.6 (22), HealthKit present, get-task-allow false, APNs production. Xcode upload succeeded.
- Both artifacts were checked to contain 940 catalog rows and 60 categories.
- No physical phone was connected during this task, so no new physical-device login/camera/health test is claimed. Existing app logic was retained; unit/widget regression tests passed.
- No real Gemini requests, billing changes or purchases were made. No API keys, signing files or private configuration were committed. No new environment variables or dependencies are required by the source changes. Java 21 was installed locally to match the existing Gradle 8.14 setup.

AAB SHA-256: `c494bfed20ea68175f43965b2e355c64e0cac709a2b265c135a8a1a934c9cf49`.
IPA SHA-256: `7601bd9ad352677c1b18a39ed5b4fcd1ba5a5c8ee2aeed2598c4dc7dbfa098b0`.

## GitHub and release status

Both repositories use the isolated branch `codex/bnyad-catalog-completion-2026-11-04`; the existing `codex/bnyad-production-repair-2026-10-25` delivery branch is also advanced with a normal fast-forward push after verification. Flutter runtime/catalog source: `b1806c4ded4fb154c405a078a191e24d7331e162`. Backend: `bf053c9d2099591598698680d912f864f74257a6`. Both pushes were verified against GitHub. The pre-existing uncommitted OTP/camera/tablet work remains intact in the original checkouts and is not part of this catalog-only release.

Prior 1.0.5 status was verified as Apple Ready for Distribution / public version 1.0.5 and Google Play production Published, available in 178 regions. The owner confirmed the installed App Store version is already 1.0.5, explaining the absence of an Update button for that version.

New Apple 1.0.6 (22): **Waiting for Review**, verified in App Store Connect. Submission ID `777aa347-a9f8-443a-b874-66b14c202520`. The owner personally completed the export-compliance declaration. Existing working private reviewer credentials were retained and the notes describe this release. Automatic release after approval and immediate rollout remain selected.
New Google Play 1.0.6 (22): **Changes in review**, verified in Publishing overview. Existing production track `4697570816641706133`, release draft number 8, 100% rollout to the existing targeted countries; managed publishing is off. Google automated quick checks are part of the submitted review process. Compatibility comparison shows 12,613 phones and 6,831 tablets supported, with zero lost devices. The first file-picker selection mistakenly chose the old 21 AAB with the same filename and was rejected as already used; it was removed from the draft. The uniquely named, certificate-verified 22 artifact was then accepted and is the only new release artifact. No earlier release was removed or changed.

Existing bundle/application IDs, store listings, reviewer account, Premium authorization, AI consent/quotas, notification setup, HealthKit and Health Connect are preserved. Automatic release after store approval remains the intended rollout; upload alone is not a public release.

Private proof screenshots (excluded from GitHub): `apple-1.0.6-22-waiting-review.png` and `google-play-1.0.6-22-in-review.png` in the owner’s private release folder. Both updates are submitted for approval, not claimed publicly live. No further owner action is currently required.
