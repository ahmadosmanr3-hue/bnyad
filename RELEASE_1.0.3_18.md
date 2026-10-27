# BNYAD 1.0.3 (18)

Prepared 27 October 2026 on `codex/bnyad-production-repair-2026-10-25`.

## Changes

- Map the existing server `ai_age_restricted` rejection to a specific adult-profile message in English, Arabic and Kurdish Sorani, preserving all server eligibility checks.
- Explain age eligibility, Google data-sharing consent, the shared daily allowance and spending safeguards when Premium reports AI available. The existing unavailable notice remains for disabled service.
- Correct the store metadata draft to describe enabled AI. Preserve the store name **BNYAD: Calorie & Macro Tracker**, design, nutrition calculations, authentication, subscriptions and health tracking.

## Verification

- `flutter analyze`: no issues.
- `flutter test`: 417 passed, including new localized eligibility error and 320/390-pixel Premium tests in all three languages.
- Backend offline tests: 174 passed. No backend source, deployment or database migration is required by this client change.
- The owner confirmed food scans, daily meal plans, ingredient recipes and fridge results work in the published app. The new copy/error mapping is covered by mocks; body-photo analysis has not been newly tested live. No automated paid Gemini calls or retries were made.
- Signed Android AAB: package `com.bnyad.app`, version 1.0.3/code 18, existing upload certificate verified; signature verified. SHA-256 `69a9f3736063ad0433b3ad3e0a7a7f0861cafcfffc4ba08fce6b782bca8ffe0c`. Read-only step/distance and camera permissions preserved; broad media permissions remain absent.

- Signed iOS IPA: bundle `com.nutrify.bnyad`, version 1.0.3/build 18, distribution signature verified. Production push and HealthKit entitlements preserved; `get-task-allow` is false. SHA-256 `b6816093fa5e058490b71a9961892009511f8501dd64d41be4e77fd2d98d9e7c`. Flutter reports the existing default launch-image warning; the app icon and launch assets were not changed in this patch.

## Runtime and release constraints

AI remains backend-only, authenticated, Premium-authorized, adult-profile restricted and consent-gated. The current shared daily allowance is 9. Monthly spending controls are managed separately on the backend; releasing this binary does not change them. Do not embed provider keys or local development configuration in either release.

Existing Apple bundle `com.nutrify.bnyad`, team `632WWWM8AH`, and HealthKit entitlements must remain unchanged. Use the existing internal TestFlight group and owner-confirmed export declaration as required. Store upload/review state will be recorded separately after actual verification; this document alone does not claim submission or approval.
