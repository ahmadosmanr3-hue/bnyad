# BNYAD 1.0.9 (25) — final release verification

Verified on 19 November 2026, Asia/Baghdad. This records actual submissions, not a claim that either update is publicly available.

## Store submissions

- **Google Play: Changes in review.** Existing app `4973400403852746672`, package `com.bnyad.app`, production release **25 (1.0.9)**. Google accepted and processed the exact signed AAB recorded in `../DELIVERY.json`. Final supported-device comparison showed no devices lost. Full rollout is 100% in the existing targeted countries; managed publishing remains off, so approved changes publish automatically. The developer personally saved Google's newly required app-level trader declaration. Both the production release and that declaration were submitted. Google's quick checks completed and the console confirmed: “Your changes are now in review.”
- **Apple: Waiting for Review.** Existing app `6781387722`, bundle `com.nutrify.bnyad`, version **1.0.9**, build **25**. The verified archive uploaded successfully through Xcode, processed, and was attached to the new version. Build resource ID: `02d8daa0-aed0-4ead-a661-cf12a8ca23eb`. The account holder completed export compliance. “1 Item Submitted” was followed by “Waiting for Review.” Automatic release after approval and immediate availability to all users remain selected. Existing reviewer credentials, screenshots, listing name and account configuration were retained.
- Listing name remains **BNYAD: Calorie & Macro Tracker** on both stores.
- Neither store has yet confirmed approval or publication. Review duration is controlled by Apple/Google. No duplicate upload or new app listing was created.

Console links: [Google Play publishing overview](https://play.google.com/console/u/0/developers/5362702642120308085/app/4973400403852746672/publishing), [Apple version](https://appstoreconnect.apple.com/apps/6781387722/distribution/ios/version/inflight).

## Final checks

- PASS — fresh Flutter analysis; all **521 Flutter tests**.
- PASS — fresh backend typecheck; all **232 backend tests**. The production Next.js build had already passed for the unchanged runtime source.
- PASS — real isolated loopback PostgreSQL integration: normal authentication, consent, server catalog calculations, concurrent/idempotent saves, historical fixture preservation and cleanup of the fictional test account. No migrations or Google calls.
- PASS — prior native scanner/editor flows on Android phone/tablet emulators and iPhone simulators, including English, Arabic, Sorani, RTL, themes, portions, correction controls, rapid-save protection, failure states, and saved diary results. Those tests use explicitly mocked recognition and the same release source.
- PASS — exact signed Android AAB installed as version 25 over the existing emulator installation without uninstalling. Its actual welcome screen opens; the app remains running with no fatal or Flutter error lines. [Release startup screenshot](android-production-startup.png).
- PASS — both artifact signatures, production bundle/application IDs, version/build numbers, production API configuration, release settings, HealthKit/Health Connect permissions, notification configuration and absence of development-only flags checked. Existing upload certificate matches. The iOS exported binary matches the archive uploaded to Apple.
- PASS — production health/catalog, normal authorization rejection on protected endpoints, and disabled development readiness. Public catalog remains **942 records, revision 3**. Existing client endpoints are retained. The new strict scanner-save endpoint is additive.
- PASS — final tested source is already pushed in both official repositories. This follow-up changes only release documentation/evidence; compiled source is unchanged.

## Source and production backend

- Branch in both repositories: `codex/bnyad-food-system-phase-2`.
- Flutter compiled source: `4294adefd0a512cf26872780454bbf4540b62184`. Previous delivery/docs head: `fa3df67c36b3623ec97128eb3c8e930935b12546`; later changes only update release records.
- Backend repository head: `3b1f37543174baf78232f8eb3427ec9da4d542ac`.
- Production runtime: `85ea8e282bbb5b90cada194e99ff3b1679301958`, existing READY deployment `dpl_H8gU3cazoVogFTaY65QzeLkt1wNx`, serving [the production API](https://nutrify-api-lovat.vercel.app/).
- No additional backend deployment, environment change, dependency change or database migration was necessary for this final submission.

## Limits of verification

No new physical-device scanner, OTP, push, HealthKit/Health Connect or store-purchase restoration test was performed on build 25 in this final submission task. Automated regression coverage, previous native evidence and preserved platform configuration are recorded separately from physical-device proof. The exact App Store IPA cannot run directly in the simulator; iOS scanner UI verification used the corresponding native test build.

No new live Gemini request was made. The development request ledger remains **21**. Real recognition accuracy and the benefit of the second photo remain **unverified**; the release improves editing, confirmation, calculations and safe logging. No paid billing changes, real purchases, test pushes or production-user data edits were made. Existing production histories were not downloaded; preservation is supported by unchanged schema/legacy contracts and isolated historical fixtures.

iOS remains officially iPhone-only. Unsaved scan drafts do not survive process termination; confirmed meal logs persist normally. Apple also displays future China-mainland compliance notices with a 31 January 2027 deadline for existing apps; these did not block this submission and no legal declarations beyond the account holder's export-compliance action were made by the agent.
