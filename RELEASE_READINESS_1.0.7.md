# BNYAD 1.0.7 (23) — exact candidate verification

November 6, 2026. **Public release: HOLD. Neither update was submitted for public review or production rollout.** User permitted public release only if judged ready; Samsung evidence remains unavailable, so both-platform readiness is not established.

## PASS — completed evidence

- Official Google bundletool 1.18.3 validated the existing AAB: com.bnyad.app, 1.0.7/code 23, debuggable=false. Official download SHA256 verified. Local upload certificate had already been checked against the existing keystore.
- Google Play accepted code 23 on **internal testing only**, track 4701483632780787808, release 1. Console shows “Available to internal testers”; no testers are configured, so nobody can opt in yet. No production promotion was made; published baseline remains code 22/1.0.6.
- iOS archive uploaded successfully using Xcode, preserving version/build 1.0.7 (23); processed build ID 34613cfb-50ea-42ae-915d-de0163a48fa4. Owner personally accepted the updated developer agreement and saved export compliance. Existing internal group “ahmed test” (five testers) remains unchanged; no external TestFlight/App Review request made.
- Physical iPhone 15 baseline verified by devicectl --include-all-apps: production bundle com.nutrify.bnyad, 1.0.6 (22). After TestFlight installation, the same command independently confirmed 1.0.7 (23). No uninstall command was used.
- User confirmed published-to-TestFlight upgrade preserved authorized test-account meals/history, favorites, Premium, language, step goal and session after restart. This is physical manual evidence, not an independent database checksum.
- User confirmed exact TestFlight candidate: English/Arabic/Sorani food search, favorites, Recent, barcode camera and optional second-photo capture/retake/remove, real Health steps/calories. Photo analysis was cancelled; no Gemini request was made.
- User confirmed an existing sandbox purchase restored and Premium remained active after restart; no purchase or real charge was made. No admin grant was counted as proof of a store restore. This is user-confirmed UI evidence; a new independent RevenueCat transaction audit was not obtained.
- User confirmed password login and persistence, then real OTP verification on a separate fictional account using a number they control. **Actual delivery is WhatsApp via OTPIQ, not SMS.** User entered credentials/code privately and confirmed the session survived restart.
- Recipient-only push “BNYAD RC23 LOCK-01”, admin notification ID 9: one Firebase acceptance, zero failures. User confirmed that exact alert on the locked iPhone and tapping it opened TestFlight BNYAD. No broadcast or repeat send.
- Latest source validation: Flutter analysis clean, 468 Flutter tests and 192 backend tests passed; backend typecheck passed. Measured rice/pizza/drink nutrition regression and RTL/volume tests passed. Physical manual measured-portion comparison was not separately recorded.
- iOS launch placeholder fixed with the existing BNYAD icon and aspect-fit constraints; storyboard validation clean. Rebuilt/exported IPA has no placeholder warning; production identity, HealthKit and production push entitlement verified in exported IPA. Android runtime sources/packages were unchanged by this fix.
- Fresh prior verification preserved all original 940 food IDs and nutrient/reference values (942 total). Catalog import code does not rewrite user logs; local transactional history/favorite preservation tests passed. Complete production-history pre/post checksum unavailable; no independent full-history equality claim.

## BLOCKED / NOT VERIFIED

- Samsung unavailable; ADB detected no Android device. Identity SM-G990B2 has NOT been reverified in this run.
- Exact Android candidate camera/two-photo UI, food/search/favorites/Recent/serving layouts, Health Connect, real steps, notifications, OTP/login, sandbox restore and session persistence require the physical phone.
- Android upgrade from published 1.0.6 to internal 1.0.7 without data loss remains untested. Do not uninstall or install an upload-key/debug-signed APK over the Play Store app. Use the Play-signed internal release and the correct test Google account.
- Android internal testers need configuration. Add only the user-designated Google account privately in Play Console; do not enable public/open testing or add unapproved lists.

There were no observed functional failures in completed exact-iOS checks. Missing Android evidence is not a passing test and prevents a final both-store approval recommendation. No source defect was discovered requiring a further rebuild during this exact-candidate pass.

## Delivery and next actions

Branch: codex/bnyad-food-system-phase-2 in both official repositories. Mobile tested source commit ff4942b7aacb08eb5528b956dbd9b7f5de83e2db; backend source/handoff baseline f519452ec7c51e941bfd48e74d40ebb6d6bb984c. Runtime backend remains 61649220e410557e28c86047799df745437ad96e. This report and INTERNAL_TEST_EVIDENCE.json are documentation-only follow-ups; final remote branch hashes are reported in chat after verification.

Next: connect Samsung, select its test Google account for the private track, test Play-signed upgrade and all Android native/service checks. Review unresolved checks, then obtain/confirm public rollout authorization only when both-platform mandatory gates pass. Preserve the 350 candidate drafts, 783 unresolved contexts and all raw research evidence; none was imported/discarded in this verification.
