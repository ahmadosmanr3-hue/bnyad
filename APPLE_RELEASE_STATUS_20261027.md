# Apple release verified — 27 October 2026

Later operational update: [production AI was separately enabled with the owner's $30 October cap](SERVER_AI_AND_FINANCE_HANDOFF.md), and [Google Play production 17 (1.0.2) is also verified Published](ANDROID_RELEASE_STATUS_20261027.md). The AI-off statement at the end below describes the initial Apple-release check, before that separately approved backend activation.

Read-only verification in the owner's signed-in App Store Connect session:

- App ID: `6781387722`; existing bundle identifier `com.nutrify.bnyad`.
- Version **1.0.2**: **Ready for Distribution**.
- Selected/released build: **16**, Apple build ID `165908c3-c46e-45ab-a79e-d8d62803f69f`.
- Store name: **BNYAD: Calorie & Macro Tracker**.

The public Apple lookup for the Iraqi storefront also returned the same name, bundle ID and version **1.0.2**. Apple reported current-version release time `2026-10-26T21:52:07Z`, which is **27 October 2026 at 00:52:07 Baghdad time**. This confirms the public Iraqi listing is updated, beyond the private review status. Other storefront propagation and updates on every installed device were not tested.

[Public Iraqi App Store listing](https://apps.apple.com/iq/app/bnyad-calorie-macro-tracker/id6781387722)

[App Store Connect version](https://appstoreconnect.apple.com/apps/6781387722/distribution/ios/version/deliverable)

No submission, release setting, legal declaration, subscription price or Apple account configuration was changed during this check. The owner’s existing submission/release process produced this status. No Android release action was taken. AI remains server-disabled; this store approval does not enable it.

## Later update: 1.0.3 (18) submitted

On 27 October, signed production build 18/version 1.0.3 was successfully uploaded through Xcode. Apple completed processing, and the owner personally saved its export-compliance declaration. Build 18 was then selected in the 1.0.3 version draft with corrected English AI copy, release notes and reviewer guidance.

App Store Connect confirmed **1 Item Submitted**. The final submission record shows **Waiting for Review**, with **iOS App 1.0.3 (18)**, submitted **27 October 2026 at 6:58 PM** as displayed by Apple. Submission ID: `86205567-eec4-4d4d-8e33-8f03d96961a4`; build ID: `8f7d451b-7f7a-446b-beaa-50e288294560`.

[Apple submission record](https://appstoreconnect.apple.com/apps/6781387722/distribution/reviewsubmissions/details/86205567-eec4-4d4d-8e33-8f03d96961a4)

This confirms submission, not approval or public availability of 1.0.3. Existing 1.0.2/build 16 remains the last verified public iOS release. The existing automatic post-review release setting, app identifiers, internal TestFlight groups and ratings are preserved. No new physical build-18 smoke test was claimed; the patch's localized error/display behavior passed automated tests, and signed production artifacts passed validation.

See [candidate verification](RELEASE_1.0.3_18.md).

## 28 October: iOS startup-crash hotfix submitted

Version **1.0.4 (19)** is **Waiting for Review**. Apple submission `380ee937-1393-43dd-9caa-d27508911dd5`, submitted 28 October 2026 at 3:07 PM (console display time); build `a0d023c0-584c-4f95-9a88-4f1ff292f090`. The owner personally saved its export declaration. This supersedes the prior release's submission status, without claiming public hotfix availability.

[Submission](https://appstoreconnect.apple.com/apps/6781387722/distribution/reviewsubmissions/details/380ee937-1393-43dd-9caa-d27508911dd5) · [Confirmed cause and verification](CRASH_HOTFIX_1.0.4_19.md)
