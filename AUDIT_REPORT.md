# BNYAD audit and implementation — 13 October 2026

Historical stability audit: the subsequent AI repair supersedes the direct-client Gemini findings below. See [AI_RELEASE_HANDOFF.md](AI_RELEASE_HANDOFF.md) for current architecture, tests, configuration and remaining live-release gates.

## Repository and production identification

Both official repos began with identical backend-only history at `873d26e93b62044bfbc3cb37ddce61210bd17338`. The real Flutter app was found in nutrify at `92b3b6b9ac17358155c5e76c8eed6f851464ab17` and imported into bnyad with owner approval. Existing mobile identity, screens, assets, fonts, food database and architecture are retained; credential-bearing configuration was excluded. Original repository histories/main branches are preserved. Backend changes are mirrored in both official delivery repositories; deploy only bnyad-backend/vercel-api.

Documentation and mobile source defaults identify the Next.js/Vercel/Neon backend. Its health endpoint was reachable during inspection. The installed store binaries and their build-time overrides were unavailable, so their actual runtime configuration cannot be independently certified from this source review.

## A. Authentication: findings and changed files

Confirmed source defects: auth loading ended before asynchronous profile/onboarding restoration; there was no durable authenticated profile fallback; API snake_case fields were passed to a camelCase model, resetting some profile/macro defaults; failed deletion always discarded the local session; HTTP failures did not distinguish true revocation from temporary failure; secure writes were not read back; iOS Keychain Sharing configuration was missing; API logging exposed credentials and health payloads.

- `lib/services/api_service.dart`: secure credential storage/migration/read-back, encrypted user/profile/current-data snapshots, pending profile upload, 401 invalidation, bounded requests, snake/camel adapters, injected test transport/storage, safe logging and deletion failure preservation.
- `lib/providers/app_state.dart`: restores profile before routing, retry state, fetch coalescing, identity checks and account-specific local state.
- `lib/main.dart`: initialization/retry UI and optional services after runApp.
- `lib/services/local_account_cache.dart`: preserves and separates local data when accounts change.
- `ios/Runner/Runner.entitlements`: Keychain Sharing entry, preserving original team/bundle settings.
- `android/app/src/main/AndroidManifest.xml`: disables backup that could restore encrypted preferences without their original keystore key.

Saved credentials/profile survive restart. Offline/timeouts/server failures preserve the session; genuine HTTP 401 clears it. Older sessions with no cached profile show retry until onboarding can be resolved safely. No auth bypass or shorter token lifetime was introduced. Pending onboarding completion is preserved securely and retried rather than replaced with stale server defaults.

The precise cause in installed store binaries was NOT reproduced on a physical device. The confirmed startup/profile defects are fixed and storage is strengthened. Actual signed upgrade/reboot/keychain testing remains a release requirement.

## B. Sorani and RTL

Catalog coverage tests check all 602 leaf entries, nested keys, lists and placeholders across English, Arabic and Sorani. A missing Arabic meal-detail hint was repaired. Canonical `ckb` is accepted while legacy `ku` identifiers remain compatible with stored data, food names and AI JSON.

Corrections include macronutrient terminology, body units, activity, meal names, hypertension/thyroid labels, peanut/corn labels, account and OTP messages. Subscription/billing/restore errors, policy links, save/startup errors and English backend auth errors now have localized wording. Displayed store prices come from the SDK or a localized placeholder; hard-coded USD discounts were removed. Subscription management opens the appropriate platform store.

Reviewed areas include splash/welcome/login/registration/OTP, onboarding/health inputs, dashboard, food/water/weight/meal tracking, scanner/meal plans, progress/weekly summaries/body-fat screens, subscriptions, notifications, settings, account deletion and shared widgets. Forms/settings/list padding use direction-aware properties; phone input stays LTR. Charts/numeric values were not blindly reversed. Locale-alias and compact RTL render tests pass.

This is not native-speaker certification. Regional food names, medical terminology, AI output, long disclosures and stock Material/Cupertino/platform dialogs require native-speaker/device review. Catalog coverage does not prove every device layout is free of clipping. See `docs/SORANI_GLOSSARY.md`.

## C. Application repairs

- Restored startup profile/onboarding state; preserved authentication through temporary failure.
- Kept failed account deletion from signing users out or discarding their data.
- Fixed API profile round trips, including macros and extended preferences.
- Replaced local food IDs with server IDs, fixing immediate deletion.
- Food/water/meal-plan saves now preserve prior state and show a localized failure when rejected. Food/barcode dialogs only close as successfully saved after server confirmation.
- Refreshed encrypted current-data snapshots after successful writes; excluded failed historical reads and checked account identity before applying results.
- Stopped recording the profile's weight as a new measurement on every startup.
- Added splash/camera async lifecycle guards; eliminated duplicate push listeners/token logging; notification taps open the inbox after authenticated startup.
- Removed web self-granted premium, guessed store expiry extensions, guest premium bypass and premium-driven completion of health onboarding.
- Removed Android debug-signing fallback for release builds; use the existing private release key.

Existing nutrition/macro/body-fat/barcode/weekly-summary tests remain passing. New food/water/meal-plan writes require a successful connection; a general durable offline mutation outbox remains separate work. Local favorites/vitamins/recipes/shopping data is preserved and separated by account, not newly migrated to the production API.

## D. Backend repairs and compatibility

- `lib/auth.ts`, `lib/security.ts`: new tokens stored as digests; compatible migration of existing 80-character bearer tokens; stored digests cannot be replayed; logout revokes both forms.
- Auth routes/security SQL: database-shared atomic rate limits, Retry-After and fail-closed missing-table handling; cryptographic OTPs; production demo codes blocked; delivery failures remove their OTP and return failure; atomic attempt reservation/single-use claiming; registration input checked before consuming an OTP.
- `lib/subscription.ts`/subscription route: trusted RevenueCat verification tied to authenticated identity; client expiry/amount ignored; repeated sync updates one verified store row; actual store revocation leaves manual subscriptions intact. Existing legitimate/history rows are not deleted.
- `lib/validation.ts`/data routes: profile field allowlist blocks ownership/primary-key/nested-relation changes; bounded values and strict dates; user-scoped deletion; atomic meal-plan replacement.
- `lib/http.ts`/all route handlers: consistent masked JSON errors, bounded JSON, no-store responses and required CORS headers. Database outages return 503 rather than pretending a saved session is invalid.
- Admin: constant-time shared-secret comparison, login throttling and in-memory browser handling instead of localStorage. Roles/MFA remain future work.
- Deployment: builds no longer synchronize database schemas. One additive SQL table is applied manually. Both Vercel project-root configurations disable Git deployments.
- Dependencies/lockfiles: Next.js stays on major 15, Firebase Admin uses modular APIs, PostCSS overridden to patched version; zero known npm advisories at verification.

No production data was modified, reset or replaced. Existing token lifetimes were not shortened. Subscription POST behavior intentionally changes to fail closed without server verification. See RELEASE_HANDOFF.md for required configuration, staged migration ordering and token rollback implications. Laravel remains an optional/reference implementation, not a production migration.

## E. Verification and limits

Passed: Flutter analysis with no issues; 49 Flutter tests (including session/offline/error/migration, profile, deletion, local account separation, stale-account response isolation, server log IDs, save failures, translation coverage and 4 startup/RTL widget tests); Android debug APK with Java 21; JavaScript Flutter web release build; 20 backend route/security tests; TypeScript; Next.js production build on Node 24.20.0; Prisma schema validation; npm audit with zero known advisories.

Unsigned iOS build was attempted with Xcode 27 and stopped because CocoaPods is missing; some plugins still require it alongside Swift Package Manager. WebAssembly dry-run warns about a third-party flutter_timezone cast; the successful web target is JavaScript.

Not claimed: signed store builds, physical-device/simulator force-stop/reboot/update-in-place tests, live PostgreSQL migration/integration execution, real provider OTP, RevenueCat purchases/restores/refunds, APNs/FCM, live AI provider, or full native-speaker approval. HTTP/keychain/backend regression tests use isolated mocks. PHP/Composer tests were not run for the inactive Laravel references.

## F. Delivery and remaining release work

Both official repos use `codex/bnyad-stability-2026-10-13`. Exact verified remote commit hashes are supplied in the delivery message. Main branches and original nutrify are unchanged. RELEASE_HANDOFF.md contains pull commands, all environment names, manual SQL, dependency requirements, signing instructions, compatibility risks and the remaining 16-scenario device auth QA matrix.

No production deployment or store submission is part of this task. Remaining items include direct AI credential handling (a dart-define is not secure secret storage), complete native/system-dialog localization, a general offline write outbox, shared-secret admin access, historical subscription/operator review and actual signed device/keychain validation. These limitations are explicit and are not reported as completed fixes.
