# BNYAD 1.0.7 (23) — public store submission record

November 6, 2026. This record supersedes the earlier release HOLD **as an authorization decision only**. The user explicitly instructed proceeding with public updates despite unfinished Android checks and lack of time. No missing test has been relabeled PASS.

## Verified store outcomes

- **Google Play: Published.** Submission 15 explicitly lists production 23 (1.0.7), Start full rollout and Published. Production track 4697570816641706133 / release 9, full rollout to targeted countries. Availability on individual devices can lag the console. The internal release was promoted; the existing validated AAB and app identity/signing were retained.
- **Apple: Waiting for Review.** Submission c6f16a19-3f35-4789-9907-f6818b57f2b9 contains iOS 1.0.7 (23), build ID 34613cfb-50ea-42ae-915d-de0163a48fa4. The console confirmed “1 Item Submitted,” then “Waiting for Review.” Automatic release after approval remains selected. Submission is not approval/public availability.
- Store name remains **BNYAD: Calorie & Macro Tracker**. Public release notes describe cleaner food search/logging, improved favorites/recents, measured portions and optional side-photo review. Internal-only notes were removed and the final public notes verified before submission. Existing privacy, pricing, subscriptions, screenshots and reviewer sign-in fields were preserved; reviewer notes were updated to 1.0.7 without publishing credentials to Git.

## Android verification boundary

A physical Xiaomi model 220333QPG, Android 11 / SDK30, was connected and authorized through ADB. Published BNYAD 1.0.6 (22), installed by Google Play, was verified; the user confirmed it works and prepared a baseline. The published base APK signature was checked locally and its certificate baseline saved in ignored build outputs. A dedicated one-account internal tester list was created/selected; the pre-existing 15-account list was left unselected. The user reported “You are a tester,” but the device still offered Open for version22. **Build23 was not installed or physically tested on this Android before the user ended further checks.** Android upgrade persistence, camera/two-photo controls, Health Connect/steps, push, OTP and store restore remain unverified for this candidate. No application data was cleared or uninstalled.

## Previously completed evidence and unchanged source

Exact iPhone TestFlight build23 and its 1.0.6-to-1.0.7 upgrade were verified as documented in INTERNAL_TEST_EVIDENCE.json, including user-confirmed retained data/session, food workflows, camera controls, real Health data, existing sandbox restore, real WhatsApp OTP, and one recipient-only locked-screen push. Latest automated checks were clean analysis, 468 Flutter tests and 192 backend tests. Launch placeholder was corrected and exported IPA signing/HealthKit/production push entitlements verified. No new runtime source changes were needed for these submissions.

Flutter runtime source: ff4942b7aacb08eb5528b956dbd9b7f5de83e2db. Deployed backend runtime: 61649220e410557e28c86047799df745437ad96e. Branch in both repositories: codex/bnyad-food-system-phase-2. Documentation-only follow-up commits record the authorization and console outcomes. Exact final remote hashes are reported in chat.

No new Gemini request, purchase, billing change, backend deployment or database migration was performed for public submission. All research, the 350 blocked candidates and unresolved contexts remain preserved; no uncleared data was imported. Users’ reports may identify further issues, but they do not replace the unfinished Android verification.
