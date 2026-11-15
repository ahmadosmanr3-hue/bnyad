# Physical-device release verification — 2026-11-16

Overall: HOLD. iPhone development-device checks passed with owner confirmation; Samsung physical checks and the actual single/two-photo Gemini comparison remain incomplete. No production deployment, billing change, migration, mobile upload or store submission occurred.

## Tested source and build identity

- Main source branch: `codex/bnyad-food-system-phase-2`, tested source `29ddec73841db775dffa260a83e0cbf79f3244a9`; verified remote handoff tip before this addendum `0c2e8b304adab659b1ce468dd2f494f2981803fd`.
- Backend same branch, tested source `a80e1a5bb84f9f5b8c12a9a614030c5fd14f7dd8`; verified remote handoff tip before this addendum `580550d9a1b8ad42c00c0fb127862eb308ba94e0`.
- iPhone 15, iOS 26.6.2, paired over the private local network. Latest source was rebuilt as a development-signed Profile build and installed/launched as **com.nutrify.bnyad.dev**, with `BNYADOfflinePreview=true`, HealthKit entitlement and team `632WWWM8AH` verified from the signed app. Bundle version is 1.0.7 (23) for local testing only, not a new store submission.
- Published bundle **com.nutrify.bnyad** remains separately installed, verified in device inventory. No uninstall command was run. This check is not an exact production-signed release-candidate or store-upgrade test.
- Application account/nutrition data is fictional and offline. Native Health readings remain real and device-only. Gemini/network calls are disabled in this preview. No production backend/account/database is used.
- Samsung was unavailable by owner confirmation; ADB detected only the emulator. No physical Android installation or verification is claimed.

## Physical iPhone checklist

These functional results are **owner-performed and owner-confirmed on the installed iPhone build**. Codex verified build/signing/install/launch directly. Xcode Device Hub could not remotely screen-share/control iOS 26.6.2 because its screen-sharing feature requires iOS 27; no simulator image is represented as a physical-device screenshot. No clean physical portion/camera screenshot has been retained as evidence so far; screenshots containing unrelated apps/video overlays are excluded from Git.

- PASS (owner): cooked white rice, 3 tablespoons. The declared USDA cup weight yields a rounded estimated 9.9g/tablespoon, 29.7g total, 38.6 kcal. This is a household estimate, not a weighed portion.
- PASS (owner): Kurdish biryani with chicken, a user-entered fictional full bowl of 300g at half fill: 150g, 297 kcal. No universal bowl mass is assumed. Existing biryani nutrition remains explicitly a recipe estimate.
- PASS (owner): Kurdish biryani with oil, a user-entered fictional full plate of 400g at 75% fill: 300g, 705 kcal.
- PASS (owner): USDA regular-crust cheese pizza, entered 90g/slice, 2 slices: 180g, 482.4 kcal. The 90g test value is not a catalog-wide slice conversion.
- PASS (owner): whole milk, 330mL bottle, quantity 2: 660mL, approximately 415.2 kcal; 0.25L, quantity 2: 500mL, approximately 314.6 kcal. Milk retains its existing food-specific documented reference conversion; no new density assumption was added.
- PASS (owner): controls were reported clear, with no confusing or clipped inputs during those cases.
- PASS (owner): physical food-camera capture and preview; genuine second capture; retake, remove, add again, cancel; selecting a sample image through the system photo library. No live Analyze action was requested. This verifies camera/input interaction, not recognition accuracy.
- PASS (owner): after a full close/reopen, language and step goal persist; real Health steps and walking calorie estimates load; no crash reported. No Health data is included in this report.
- PASS (previous automated evidence): 492 Flutter unit/widget tests, clean Flutter analysis, 202 backend tests, TypeScript check and Next.js production build. Six emulator/simulator configurations exercised EN/AR/KU, RTL and light/dark. These were completed on the tested source; this addendum changes documentation/evaluation-plan data only.
- PENDING: independent physical screenshot review and broader keyboard/accessibility/device-size usability observations. Owner feedback is not presented as Codex-controlled visual inspection.
- PENDING: exact production-signed Android/iOS release-candidate, upgrade/data-retention and final store-specific smoke checks after approved release packaging. Production auth/OTP/push/purchases were not exercised by this offline build.

## Real Gemini evaluation: approved scope, prepare only

Owner approved **12 additional Google HTTP attempts**, maximum **6 scans**, **$0.10 total ceiling**, cumulative development count **21 → at most 33**. Each scan permits at most one token-count request and one generation. No metadata calls, retries, fallback-model calls or uncounted attempts are included. A failed/uncertain request must not be refunded or retried.

The owner then confirmed **no genuine paired images are ready; prepare the evaluation only**. Consequently zero new live requests were made, the existing private ledger still records 21, and no transport was armed. The old one-use 21-request gate was not relaxed. A new scoped, offline-tested local admission mechanism is still required before this approval can be exercised; changing a JSON proposal alone must never enable calls.

Proposed three known-identity meals: Kurdish biryani, Iraqi dolma/yaprax and Arabic shawarma. For each, compare one top image with a top/side pair of the **same unchanged portion**. Do not use a repeated photo as another view, and do not invent hidden ingredients, identities, weights or camera geometry. The current licensed research photos lack paired side views; they are unsuitable for a claimed paired comparison.

Where an edible portion can be independently weighed, keep the reference weight in local adjudication records and **withhold it from the model** during portion-estimation evaluation. Otherwise portion error is unscored. Supplying the answer as `foodGrams` would test obedience to a measured input, not portion-estimation accuracy. The separate measured-input-priority safeguard already has offline regression tests.

Use normal authenticated fictional adult Premium users, explicit consent, restrictions, daily quota and server accounting against only the isolated loopback PostgreSQL database. Verify the selected model, exact local environment and existing ledger before arming. The future authorization must bind user, model, six image-digest/view cases, expiry, request count and cost reservation; reserve both calls and worst-case cost before each attempt and close access after each observation. No public tunnel or production account is involved. Preserve existing valid rate limits; space scans as needed instead of disabling limits.

Report every success, abstention and failure. Score food identity/confusions, mixed components, invented foods, independently measured portion error, view-level results, latency, actual token counts and token-based estimated cost. Check English/Arabic/Sorani/RTL response display. A three-meal pilot is not a representative statistical accuracy certification. Raw responses may be safely rejected by existing nutrition/allergy validators; those checks must not be weakened for the pilot.

Google Standard pricing checked 2026-11-16: $0.30 input and $2.50 output per million tokens for `gemini-3.5-flash-lite`: https://aistudio.google.com/docs/pricing#gemini-3.5-flash-lite . Illustrative 3 single scans at 4000 input tokens plus 3 paired scans at 6000, each with 800 output tokens, total **$0.021**. Actual image tokens vary. The intended 12000-input/4096-output per-generation envelope gives **$0.08304** for all six generations at those rates, before the proposed $0.10 admission ceiling. No tools/grounding/search are enabled. Recheck rates at execution time. This local ceiling is not a Google billing-account limit.

Machine-readable scope: backend `vercel-api/evaluation/paired-evaluation-plan.json`. Observations and actual accuracy remain empty/unverified. No billing setting or production AI control was changed.

## Official iPad support

Recommendation: retain the current iPhone-only shipping target for this release, and decide full iPad support separately. No device-family changes were made. Previous full-width iPad checks used a simulator-only override; they do not qualify all app screens for official support.

If approved later, audit every main/auth/onboarding/Premium/Health/camera screen in portrait/landscape, resized windows and split layouts, keyboard/focus, dialogs/popovers, camera/photo selection, accessibility, all three languages/themes and appropriate physical iPad hardware; then update the shipping target and prepare the required iPad store screenshots. Check current Apple guidance rather than suppressing requirements with a full-screen workaround.

References: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications and https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key . Full iPad support is an optional product expansion, not a defect in the current declared iPhone-only support.

## Release blockers and safe sequence

Mandatory gates not yet passed: physical Samsung checks; the requested actual paired-view recognition evaluation (pending images, scoped admission and supervised execution); exact final signed-package/upgrade verification. Optional: official iPad support is deferred and must not be advertised as shipping.

1. Finish Samsung physical measurement/camera/Health/session checks with a separate development ID and fictional account, preserving Play Store data. Collect independent physical screenshot evidence where practical.
2. When genuine nonprivate pairs are available and the owner wants to exercise the approved scope, implement/test the scoped local request/cost gate, preserve the 21-attempt baseline and all normal authorization, then conduct the six supervised observations without retries. Stop/disarm on failure, cap, revocation or expiry; record actual results. Do not treat simulated results as proof.
3. Review remaining findings and obtain explicit approval for the production backend rollout. There are **no new migrations or required environment variables** in the measurement changes. Verify existing server-only credentials, configured model/rates, consent, Premium verification, nine-request daily allowance, monthly spending control and disabled Git-triggered deployment. Never use local mock/approval files in production.
4. Deploy the reviewed **backward-compatible backend first**. Retain the previous known-good deployment. Verify legacy clients and the new catalog-calculation/component and recognition-v2 contracts, normal authorization/error paths and any explicitly authorized isolated QA records. Do not overwrite real users or rewrite historical logs. Observe logs/budgets before releasing either client.
5. Confirm latest store versions/build numbers, select the next unused versions, and build signed Android AAB and iOS archive/IPA from the approved source. Verify existing application IDs, signing/upload certificate, Health permissions/entitlements, notification setup, release guards and absence of mock/private configuration. Complete exact candidate upgrade/data-retention and sandbox restore checks through an approved testing distribution workflow.
6. Present final PASS/FAIL results and package hashes. **Obtain separate mobile release approval** before store upload/submission/publication; use staged/phased rollout where appropriate. No store release is performed by this verification task.
7. Monitor crashes, login, food/favorite/log integrity, Health and AI errors/costs. If a new API path fails, disable AI through existing server controls and investigate; never serve mock recognition to production. Keep backward-compatible contract support while any newer mobile build is installed. Reverting to an older backend can remove server-authoritative calculation behavior, so verify the rollback contract before using it; prefer a tested compatible fix.

No new production dependencies, database changes or nutritional target/formula changes were introduced by this verification follow-up. The 350 blocked food candidates and unresolved research remain preserved.
