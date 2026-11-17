# BNYAD 1.0.8 (24) production release

## Scope
Existing food measurement and portion editor, optional same-meal second-photo review, and opt-in food recognition v2. Original branding, daily nutrition targets, authentication, Premium, consent, usage guards, steps and existing food IDs/history are preserved. No database migration or food import is required.

## Final checks — 16–17 November 2026
- PASS: Flutter analysis, no issues.
- PASS: all 492 Flutter unit/widget tests.
- PASS: all 225 backend tests, TypeScript check and Next production build.
- PASS: Pixel 8 API 36 emulator native integration suite (3 tests), English/Arabic/Sorani, RTL, light/dark, portions, invalid quantities, navigation and photo-review controls. 51 screenshots retained locally.
- PASS: iPhone 18 Pro iOS 27 simulator native integration suite (3 tests), same scenarios. 51 screenshots retained locally.
- PASS: Android production AAB 1.0.8 (24), bundletool validation, JAR signature verification, upload certificate matches private saved upload certificate. Play Console upload certificate downloaded and matched exactly.
- PASS: iOS production archive 1.0.8 (24), correct bundle com.nutrify.bnyad; exported successfully after Apple-account refresh; exported package has production APNs, HealthKit, debugger disabled and no development-only flags.
- PASS: production backend READY on the existing domain. All 180 uploaded source files match their recorded SHA1 digests; health/catalog checks pass and protected routes require authentication. The 942 catalog records and revision are identical before/after deployment.
- PASS: Google Play production release 24 (1.0.8) submitted; status “Changes in review”, full rollout after approval.
- PASS: App Store 1.0.8 (24) submitted; status “Waiting for Review”, automatic release after approval. Nothing is claimed publicly available.
- PASS: Android APK derived from the signed release AAB installed and launched on the Pixel emulator; login/guest entry screen reached, with no fatal startup error recorded. No production account or AI analysis was used for that smoke check.

## Limitations
No Google/Gemini attempts were made. Recognition accuracy and single-versus-two-photo improvement are unverified. Native photo-review automation uses repeated fixture views solely to exercise UI; these are not genuine paired recognition experiments. Live evaluation remains disarmed.

Prior physical iPhone measurement/camera/real-steps checks were owner-confirmed, not repeated on physical hardware in this run. Samsung is unavailable. Emulator results do not prove hardware camera, push delivery, OTP or store purchase restoration on the new release candidate. Existing physical/store checks are documented in the previous release records.

The user explicitly authorized production backend deployment and submission to the existing listings despite the remaining live AI evaluation and physical-device limitations. No new billing, live AI calls, destructive data changes or replacement signing credentials are authorized.

## Release notes
Clearer food portion controls for spoons, bowls, plates, pizza slices and drink volumes. Review measured quantities before logging, with nutrition totals updated from the selected food. Optional second-photo guidance helps show the same meal from another angle. Improved food-photo uncertainty handling and English, Arabic and Sorani layouts. AI nutrition remains an estimate and requires confirmation. No recognition-accuracy improvement is claimed.

## Final delivery
Both stores received the existing BNYAD listing update; no new app was created. Apple submission ID: `036ec644-7914-4292-afc8-874726b0b90e`. Google Play production release: `10`, version code `24`. Publication awaits store approval; automatic/full release settings are saved.

Vercel: `dpl_DTKNnj3i1oCnJx2JTpvVJJbjSfyt`, source `673845b4c71d5072bc5d87a639071a6080a147c5`. Backend handoff commit: `ca9c489d9bf69fa1b3665fb2ec9ff7dfc2007720`. Mobile build source: `3d81ba888a4eed92857f0b60297378959577a799`; later handoff commits only update release evidence. Both repositories use `codex/bnyad-food-system-phase-2`.

See DELIVERY.json for artifact digests, status URLs and identifiers. No new production environment variable, dependency or migration is required. Signing credentials, local configuration, private account files and local databases are excluded. The retained IPA is the local verified export; Xcode uploaded the same archived build using its normal export/upload flow.

## Remaining limitations and follow-up
- Store review may still reject or request information. Check the recorded review pages before claiming publication.
- No new physical Samsung test, fresh physical iPhone exact-release test, purchase/restore, OTP or background push test was performed in this release run. Previously owner-confirmed device checks are retained in earlier records.
- Live recognition accuracy remains unverified; genuine same-portion paired images are still missing. No live Gemini test request was made.
- iOS remains officially iPhone-only. No iPad support expansion was submitted.
- Existing minor toolchain/plugin warnings remain; no critical build or store-validation failure remained at submission. Vercel returned no error/fatal log groups for the final bounded 30-minute check; this is not a guarantee of all future runtime behavior.
- The production catalog was read and compared; historical logs were not rewritten or migrated, and no new full audit of every private historical log was performed.
