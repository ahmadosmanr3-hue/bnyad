# BNYAD 1.0.8 (24) production release

## Scope
Existing food measurement and portion editor, optional same-meal second-photo review, and opt-in food recognition v2. Original branding, daily nutrition targets, authentication, Premium, consent, usage guards, steps and existing food IDs/history are preserved. No database migration or food import is required.

## Final checks — 16–17 November 2026
- PASS: Flutter analysis, no issues.
- PASS: all 492 Flutter unit/widget tests.
- PASS: all 225 backend tests, TypeScript check and Next production build.
- PASS: Pixel 8 API 36 emulator native integration suite (3 tests), English/Arabic/Sorani, RTL, light/dark, portions, invalid quantities, navigation and photo-review controls. 51 screenshots retained locally.
- PASS: iPhone 18 Pro iOS 27 simulator native integration suite (3 tests), same scenarios. 51 screenshots retained locally.
- PASS: Android production AAB 1.0.8 (24), bundletool validation, JAR signature verification, upload certificate matches private saved upload certificate. Play Console comparison remains pending.
- PASS: iOS production archive 1.0.8 (24), correct bundle com.nutrify.bnyad; App Store export pending account refresh.
- PENDING: production backend deployment and post-deploy compatibility probes.
- PENDING: Google Play and App Store package uploads/submission. Nothing is claimed publicly available.

## Limitations
No Google/Gemini attempts were made. Recognition accuracy and single-versus-two-photo improvement are unverified. Native photo-review automation uses repeated fixture views solely to exercise UI; these are not genuine paired recognition experiments. Live evaluation remains disarmed.

Prior physical iPhone measurement/camera/real-steps checks were owner-confirmed, not repeated on physical hardware in this run. Samsung is unavailable. Emulator results do not prove hardware camera, push delivery, OTP or store purchase restoration on the new release candidate. Existing physical/store checks are documented in the previous release records.

The user explicitly authorized production backend deployment and submission to the existing listings despite the remaining live AI evaluation and physical-device limitations. No new billing, live AI calls, destructive data changes or replacement signing credentials are authorized.

## Release notes
Clearer food portion controls for spoons, bowls, plates, pizza slices and drink volumes. Review measured quantities before logging, with nutrition totals updated from the selected food. Optional second-photo guidance helps show the same meal from another angle. Improved food-photo uncertainty handling and English, Arabic and Sorani layouts. AI nutrition remains an estimate and requires confirmation. No recognition-accuracy improvement is claimed.
