# BNYAD 1.0.7 (23) — final release-readiness check

November 6, 2026. **Release gate: NOT READY for both stores. No upload/submission/publication performed.** BLOCKED means not verified, not an observed functional failure.

- PASS — Flutter analysis clean; 468 Flutter tests and 192 backend tests pass; backend typecheck passes.
- PASS — Separate complete BNYAD Dev 1.0.7 (23) signed, installed and launched on physical iPhone 15. Native process confirmed running. Production bundle was not installed/replaced by this test.
- PASS (user-confirmed, physical iPhone Dev) — Text-only food logging, English/Arabic/Sorani search, star/unstar, logging and Recent after reopening.
- PASS (user-confirmed, physical iPhone Dev) — Camera and optional second-photo controls; real Health steps/calorie estimates and saved goal. AI results were mocked; no Gemini request was made.
- PASS (automated) — Measured rice/spoons, pizza slices and drink volumes/macros. Fictional numeric regression: 39 g rice = 50.7 kcal, 180 g pizza = 478.8 kcal / 19.8 g protein, 330 mL drink = 151.8 kcal / 37.95 g carbs for the explicit test references. These are test fixtures, not universal recipe values. Physical manual portion-calculation comparison not independently recorded.
- PASS — iOS launch placeholder replaced with BNYAD's existing brand icon, centered/aspect-fit at 160 points. Storyboard checker reports no errors/warnings. Rebuilt IPA no longer emits Flutter's default launch-image warning. No new branding or business logic.
- PASS — Signed iOS IPA rebuilt/exported as 1.0.7 (23), com.nutrify.bnyad; exported signature verified, HealthKit true, aps-environment=production, no offline/local-backend flags. The pre-export archive's development entitlement is replaced during distribution export; the exported IPA was checked separately.
- PASS — Existing Android AAB remains prepared/signed from Phase 2; no Android source changes in this verification. Previous signature matched the existing upload keystore. This is package validation, not a new physical Samsung test.
- PASS — Fresh read-only public snapshot confirms all original 940 food IDs and calorie/protein/carbs/fat/reference amount/unit values intact; catalog currently 942. Original research, 350 blocked candidates and unresolved queue preserved.
- PASS (bounded evidence) — Import code never rewrites/deletes user logs; local transactional tests verify historical log/favorite preservation. No production log write or migration was made. A complete pre/post production historical-log checksum was unavailable, so full historical equality is NOT independently certified.
- BLOCKED — Physical Samsung unavailable; no Android device detected. Its camera, Health Connect, settings and final native candidate still need physical verification.
- BLOCKED — Exact store-signed candidates were not installed for this check. iOS physical tests used the same Flutter source in the separate mocked Dev build, preserving the App Store installation. No internal-distribution upload was authorized in this phase.
- NOT VERIFIED end-to-end — Real login/OTP delivery, push reception/tap routing and Premium purchase/restore on the final store candidates. Existing automated regressions pass, but mocked auth/billing-disabled preview results cannot certify those services. No purchase, OTP dispatch, push or production-account change was made.

## Remaining release gates

Connect Samsung and test the final candidate. Arrange an explicitly approved internal distribution path for the exact store builds, then verify login/OTP, recipient-only push and sandbox restoration without a real purchase. Recheck physical portion examples. Obtain final user approval before uploading or submitting mobile updates. No critical functional failure was reported during completed iPhone Dev checks.

## Packages and source

Updated iOS IPA: build/ios/ipa/BNYAD.ipa. SHA256 2cdc43848aa11ff92c7a8203cdaef80cdfe3b0a8a97e2df1541570141605b471.
Android AAB: build/app/outputs/bundle/release/app-release.aab (unchanged from Phase 2), SHA256 225a962767d9824ee144623fe8c4a4e4ae3fbe136ee4ffd28444d0f7d7148a0f.

Both official repositories use codex/bnyad-food-system-phase-2. Exact final branch hashes are reported after remote verification in the chat; git rev-parse HEAD and git ls-remote origin refs/heads/codex/bnyad-food-system-phase-2 must match. This verification adds only iOS launch assets/storyboard, one numeric regression test and release documentation; no backend runtime changes/deployment are needed. Production runtime remains 61649220e410557e28c86047799df745437ad96e.
