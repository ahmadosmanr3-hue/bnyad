# BNYAD AI repair — source delivery, 13 October 2026

This document supersedes the legacy direct-Gemini notes in RELEASE_HANDOFF.md and AUDIT_REPORT.md. No production deployment, production migration, store upload, API purchase, real Google call or billing activation was performed. AI remains disabled by default. No Gemini credential belongs in Flutter or Git.

## Delivery and architecture

Both official repositories continue on `codex/bnyad-stability-2026-10-13`, starting from verified remote development heads `899c48cb4c0d82c3ab404085794e598c2ff40b5d` (main app) and `d72232811870d2e8f0399f00c1bbd7c2f7698f5c` (backend). Final new hashes are supplied in the delivery message. The authoritative backend is bnyad-backend/vercel-api; its source is mirrored in bnyad/vercel-api. No main-branch history was rewritten.

Flutter's existing feature screens now call the authenticated Next.js API, not Google. The original AI facade keeps the existing food-photo, four-slot daily plan, swap/details, ingredient-recipe, fridge, shopping and optional body-photo/tips workflows. Weekly plans were not added. BMI/BMR/macros/water/micronutrient targets remain local; automatic medical-profile requests were removed.

Endpoints:
- `GET /api/ai/consent`: current versioned server consent.
- `PUT /api/ai/consent`: `{enabled: boolean, version: "google-ai-2026-10-13-v1"}`; no default opt-in. Revocation deletes account AI caches.
- `POST /api/ai/generate`: `{operation, input}`. Supported operation IDs: food, fridge, meal-plan, meal, details, recipe, shopping, guidance, body-fat. The server owns prompts, schemas, model choice and saved profile targets/restrictions; client premium flags, arbitrary prompts and medical fields are not forwarded.

Every generation checks bearer authentication, active DB premium and current consent. A store_verified grant also requires a current RevenueCat verification; unavailable verification denies paid AI safely. Existing manual/admin DB grants remain supported. Historical grants should still be reconciled with purchase records by the operator; this task does not invalidate existing users automatically.

## Manual migration and release order

1. Back up and use an isolated staging PostgreSQL database. Review/apply the previous `vercel-api/db/20261013_auth_rate_limits.sql` if not already applied.
2. Review/apply **vercel-api/db/20261013_ai_safeguards.sql** manually. It adds ai_consents, ai_usage and ai_cache only. It does not update existing users, profiles, plans or subscriptions. Prisma schema declarations match the new tables, but builds only generate the client: they do not push schemas.
3. Deploy the backend manually to staging, initially with `AI_ENABLED=false`. Missing tables fail closed. Verify older clients still use non-AI routes normally.
4. Run backend tests/build and device tests against staging. Verify consent grant/revoke, premium/RevenueCat mapping, daily quotas, budget concurrency, cache expiration, account deletion, disabled-provider behavior and timeout recovery.
5. Only after owner approval, configure a Google credential, service terms and budget in staging, then run a small explicitly approved live test. No fixture mode exists in the production endpoint; test fixtures inject fetch/database mocks only.
6. Only the release developer performs an approved production migration/deployment and signed mobile builds/releases. Git deployment remains disabled in both Vercel configuration roots. Preserve the current Android/iOS package identities and signing keys; increment version/build numbers relative to the actual published versions.

Never run `prisma db push` against production as a migration shortcut. Never put DATABASE_URL, Gemini/RevenueCat server secrets, Firebase service accounts, keystores or signing passwords in Git.

## Server environment variables

Required to enable generation (all are server-only):
- `AI_ENABLED`: defaults false. Leave false until approval and staging validation.
- `GEMINI_API_KEY`: empty by default. Set privately in the backend hosting environment only.
- `GEMINI_MODEL`: defaults `gemini-3.1-flash-lite`; prepared alternative `gemini-3.5-flash-lite`. Retired 1.5 models are rejected. Other explicitly configured Gemini IDs require operator compatibility/pricing validation.
- `AI_INPUT_USD_PER_MILLION`, `AI_OUTPUT_USD_PER_MILLION`: explicit positive standard text/image input and output rates; output includes thinking tokens. Missing/invalid rates deny generation.
- `AI_MONTHLY_BUDGET_USD`: defaults zero, disabling paid access. Positive owner-approved monthly estimated spending cap; maximum accepted configuration is USD 10,000. The budget is shared across users/instances using the same database, resets by UTC calendar month, and is independent of per-user allowances.

Optional bounded settings:
- `AI_DAILY_REQUEST_LIMIT=10` (maximum 100 provider attempts/user/UTC day, including failures).
- `AI_REQUESTS_PER_MINUTE=3` (maximum 20 admissions/user/minute, including cache hits).
- `AI_MAX_INPUT_TOKENS=12000` (maximum 32000).
- `AI_MAX_OUTPUT_TOKENS=4096` (maximum 8192, including reasoning).
- `AI_TIMEOUT_MS=25000` (maximum 40000, one deadline for count + generate).
- `AI_CACHE_TTL_SECONDS=21600` (maximum 86400).

Retain existing DATABASE_URL, ADMIN_SECRET and RevenueCat configuration. Store verification uses REVENUECAT_SECRET_API_KEY and REVENUECAT_ENTITLEMENT_ID (default all_feature). Do not change the mobile entitlement mapping without coordinating both sides.

Flutter build configuration now contains only API_BASE_URL and RevenueCat PUBLIC SDK keys RC_ANDROID_PUBLIC_KEY/RC_IOS_PUBLIC_KEY. Remove GEMINI_API_KEY from all mobile dart-defines/release-config files; rebuilds must never embed it. No dependency additions were needed.

## Google setup — owner action and approval required

Official documentation checked on 13 October 2026 lists both requested IDs as supporting image input and structured JSON output:
- https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite
- https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite
- https://ai.google.dev/gemini-api/docs/generate-content/structured-output
- https://ai.google.dev/api/tokens
- https://ai.google.dev/gemini-api/docs/pricing

The prepared REST integration uses v1beta countTokens and generateContent, responseJsonSchema, minimal thinking, explicit maxOutputTokens, inline JPEG/PNG bytes, API-key headers and no keys in URLs. It performs no automatic fallback/retry. Documented availability is NOT proof that the owner's project/region/key can access a model; only an approved real call can establish that.

At documentation-check time, standard 3.1 Flash-Lite text/image input was USD 0.25/million tokens and output USD 1.50/million. Standard 3.5 Flash-Lite input was USD 0.30/million and output USD 2.50/million. These are configuration references, NOT billing authorization; recheck before activation. Free/paid data-use terms differ. The owner must choose acceptable terms and review retention/training provisions before enabling personal-data/photo requests. The privacy page no longer makes an unsupported blanket no-training guarantee.

Owner steps: create/select the Google project and credential privately; restrict the key to the Generative Language API where available; choose the documented model and current rates; approve an explicit spending amount and a small staging-test allowance; provide the key through the hosting environment, never chat or source. Use a dedicated provider project/key for BNYAD and provider-side quota/billing controls. No AI calls will work from this delivery until this configuration is deliberately enabled.

## Spending, caching and privacy

Admission uses PostgreSQL advisory transaction locks for a shared global budget and per-user concurrency, preventing concurrent instances from independently overspending the application's allowance. One generation may run per account at a time. Each attempt reserves the maximum configured input/output estimated cost BEFORE any Google request. countTokens rejects excessive input before generation. Successful validated responses settle to reported prompt plus output/thinking usage. Failed, refused, malformed, timed-out or crashed work conservatively keeps its full reservation because a provider charge may have occurred. Failures are not automatically retried.

Cached validated responses are private per user/model/operation/preferences/input, expire within the configured TTL and bypass generation cost/daily generation allowance, but still count for rate limiting. There is no cross-user result cache or provider-managed paid context cache. Photos are only processed in memory; cache keys use hashes, not raw photos. JPEG EXIF/GPS/comments and PNG ancillary metadata are stripped; images are bounded to 1 MB and 1600 pixels per side.

Usage records contain a request UUID, account reference, operation/model, token counts, reservation/estimated microdollars, status, UTC period/time and hashed cache key. No prompt, image, phone, name, medication or detailed medical history is logged. Account deletion cascades consent/cache deletion and anonymizes usage user_id; retained spending metadata prevents deleting/recreating accounts from replenishing the global budget. Do not delete current-period usage records to reset allowances. Expired caches are purged on account admission; schedule reviewed housekeeping to delete all expired ai_cache rows and anonymized/old usage outside required accounting retention. Do not introduce a background production job without approval.

This is an application-level ESTIMATED spending guard, not a guarantee of the Google invoice. Mispriced configuration, provider billing changes, other applications using the key, provider anomalies and external console calls are outside its accounting. Reconcile reported usage/invoice in staging and set provider-side limits. Never silently raise budget/quotas to hide errors.

## Nutrition, restrictions and confirmation

The AI selects ingredient IDs and edible portion grams from a conservative subset of the existing food catalog. Server code calculates macros/micros from catalog values; model-invented totals are ignored. Unknown IDs, bad quantities, duplicates, missing translation arrays, Latin-only Sorani, invalid daily totals and forbidden ingredients fail validation. Daily plans must be within 20% of calorie and 30% of macro targets; there is no artificial scaling of macro numbers without changing food quantities. Missing catalog micros remain unknown rather than invented.

Saved allergy categories, diet and disliked-food rules filter eligible ingredients server-side. Known allergy terms in English names/instructions are checked again. Unknown allergy categories/ingredients require manual review. Halal/kosher and pregnancy contexts conservatively use plant ingredients because certification/pasteurization cannot be proved from the existing catalog. This narrowing is intentional, not a claim of certification. Fridge recipes cannot use ingredients absent from the detected list. Typed-ingredient recipes cannot introduce catalog ingredients not selected by the user.

Allergy cross-contamination, unrecognized ingredients, instruction completeness, quantities inferred from photos, food database accuracy, medical suitability and native Sorani quality still require human/device/live evaluation. These rules reduce risk but do NOT certify a meal allergy-safe. Users must confirm estimated ingredients/portions before saving/logging. Labels and safe cooking practices remain essential.

Flutter now uses confirmed server totals, correct per-100g versus component micronutrient scaling, and summed ingredient grams. Existing daily plans and recipes remain local/cloud data under their prior storage design. A direct logging action was added to the existing custom-recipe result; no replacement feature or weekly planner was built.

## Verification and remaining release gates

Automated tests use synthetic identities, injected HTTP provider responses and isolated mocked Prisma persistence. They cover request/schema construction for both IDs, authentication/premium/consent, quotas/budget/rate/cache admission, revocation, malformed/unsafe output, catalog nutrition, restrictions, translation script checks and mobile consent/results/account isolation. Exact totals and build results are supplied in the final delivery message after final verification.

Verified during implementation: **62 Flutter tests**, **56 backend tests**, Flutter analysis with no issues, TypeScript checks, Prisma schema validation, Android debug APK (Java 21), JavaScript web release build and Next.js production build. npm audit reported zero known production dependency vulnerabilities. The unsigned iOS build was attempted and stopped at missing CocoaPods. Android emitted existing Gradle/Kotlin deprecation warnings; toolchain upgrades should be separately validated before a store release.

Disable request-body capture in any hosting/APM configuration before enabling photo features. TTL prevents reuse after expiration; physical cleanup of expired cache rows and operational backups must follow the operator's approved retention policy. No scheduled production cleanup job was installed in this task.

Not completed without owner credentials/approval: live Google model access, real image recognition, generated recipe quality/latency, live token/invoice reconciliation, real store/RevenueCat payments/refunds, production deployment, real staging PostgreSQL concurrency/migration execution, native-speaker sign-off and signed physical-device/store-upgrade QA. iOS native build validation remains dependent on the release developer's CocoaPods/signing setup. The pre-existing wider food-catalog quality and local-only synchronization issues remain separate work; suspect complex foods are excluded from AI ingredient selection rather than silently edited without nutrition evidence.

## Pull and release developer commands

In each repository, preserve local work, then `git fetch origin`, `git switch codex/bnyad-stability-2026-10-13`, `git pull --ff-only`. If absent locally, use `git switch --track origin/codex/bnyad-stability-2026-10-13`. Verify the final hashes against the delivery message.

Backend: Node 24, `cd vercel-api`, `npm ci`, `npm test`, `npm run typecheck`, `npm run build`. Use a nonproduction/staging database; migrations are manual and separate from builds.

Mobile: Flutter 3.47.7/Dart 3.13.5 as previously tested, `flutter pub get`, `flutter analyze`, `flutter test`. Android uses Java 21, private existing Firebase/signing files; iOS needs CocoaPods, existing certificates/profiles and native Firebase configuration. Use API_BASE_URL pointing at staging for live approval testing. Release builds and store submission remain the other developer's responsibility.
