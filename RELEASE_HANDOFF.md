> Latest startup hotfix: [1.0.4 (19) cause, native verification and release checks](CRASH_HOTFIX_1.0.4_19.md). Every store build must include the existing private `release-config.json` with `--dart-define-from-file=release-config.json`; native build preflights now enforce this configuration. Historical release notes below describe earlier tasks.

# BNYAD source delivery — 13 October 2026

**Latest verified status (27 October):** [Apple 1.0.2/build 16 is Ready for Distribution and on the public Iraqi listing](APPLE_RELEASE_STATUS_20261027.md). [Google Play production 17 (1.0.2) is Published](ANDROID_RELEASE_STATUS_20261027.md). [Production AI, the nine-request policy and admin monthly finances are live](SERVER_AI_AND_FINANCE_HANDOFF.md), with the owner's approved $30 October cap and confirmed real meal/food-scan responses. Static store-copy correction remains outstanding. The original 13 October source-delivery history below predates the subsequent approved production releases; use the dated handoffs for current state.

**AI integration update:** Read [AI_RELEASE_HANDOFF.md](AI_RELEASE_HANDOFF.md) first. It supersedes the legacy direct-AI configuration below: Gemini access is server-only, disabled until approved configuration, and uses an additional manual migration.

This branch is source delivery only. No production database migration, production deployment, App Store submission, or Google Play submission was performed.

## Repositories and provenance

- Mobile application: https://github.com/ahmadosmanr3-hue/bnyad
- Production backend source: https://github.com/ahmadosmanr3-hue/bnyad-backend (deploy root `vercel-api`)
- Delivery branch in both: `codex/bnyad-stability-2026-10-13`
- Both official repositories started at `873d26e93b62044bfbc3cb37ddce61210bd17338`.
- The real Flutter application was located in `ahmadosmanr3-hue/nutrify`, commit `92b3b6b9ac17358155c5e76c8eed6f851464ab17`. With the owner's approval its existing mobile source, native projects, assets, fonts, tests and reference documentation were brought into `bnyad`. Credentials and generated Firebase configuration were excluded. The original nutrify repository was not changed.
- The backend is synchronized in both delivery repositories to avoid leaving an exploitable duplicate implementation in the main app repository. Deploy one backend, from bnyad-backend.

The existing Git histories and main branches are preserved. No force push is required.

## Pull instructions

In each corresponding existing checkout:

```sh
git fetch origin
git switch --track origin/codex/bnyad-stability-2026-10-13
git pull --ff-only
```

If the local delivery branch already exists, switch to it instead of using `--track`. Preserve local signing files and uncommitted work; do not reset the developer's checkout. Commit hashes are provided in the delivery message and can be verified with `git rev-parse HEAD` and `git ls-remote origin refs/heads/codex/bnyad-stability-2026-10-13`.

## Backend setup and deliberate release ordering

1. Select Node.js 24 LTS (the supported package range is Node 22–24).
2. From `vercel-api`, run `npm ci`, `npm test`, `npm run typecheck`, and `npm run build`. Prisma generation needs no database write.
3. Back up the target database and test the additive SQL in a separate development/staging PostgreSQL database. The migration is `vercel-api/db/20261013_auth_rate_limits.sql`. It creates only `auth_rate_limits`; it does not alter or delete user, history, token, or subscription tables.
4. Apply that SQL manually BEFORE deploying the API changes. Auth requests fail closed with HTTP 503 if the rate-limit table is missing. For example, in an approved target environment: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/20261013_auth_rate_limits.sql`. Never paste a database URL or credentials into Git.
5. Set the environment variables below in the hosting provider, not in source files.
6. Test real OTP delivery, admin login, legacy-token login/logout, RevenueCat identity mapping, purchase/restore/revocation, data writes, account deletion, and push in staging before the release developer manually deploys.
7. Both root and `vercel-api/vercel.json` explicitly disable Git-triggered Vercel deployments. A Git push is not a release. Only the release developer should enable deployment or perform an approved manual deployment. Railway's legacy Laravel service must not be substituted for the active backend.

Builds no longer run `prisma db push`. Do not run `db push` against production as a replacement for reviewing migrations. No seed is needed for this delivery.

### Server environment variables

- `DATABASE_URL`: existing PostgreSQL/Neon connection.
- `APP_ENV=production`: required production intent; a production Next.js build blocks demo OTP even if this is misconfigured.
- `OTPIQ_API_KEY`: real server-only verification gateway credential. The existing gateway transport requests WhatsApp verification through OTPIQ.
- `ALLOW_DEMO_OTP=false`: production default. Set true only for local development, with a nonproduction build. Never used in production.
- `ADMIN_SECRET`: retain a strong existing secret. There is no fallback password. The admin panel now keeps it only in memory, so a page reload requires another admin login.
- `SETUP_SECRET`: retain existing protected food-seed credential if that endpoint is needed.
- `FIREBASE_SERVICE_ACCOUNT_JSON`: existing server-only push credential.
- `REVENUECAT_SECRET_API_KEY`: NEW server-only REST API secret for the SAME RevenueCat project as the mobile SDK. Never use a mobile public SDK key here.
- `REVENUECAT_ENTITLEMENT_ID`: NEW optional entitlement identifier; defaults to the existing `all_feature`.

RevenueCat must map the app user id to the authenticated backend user's numeric id, as a string. The mobile code calls `Purchases.logIn(userId.toString())`. Confirm mapping and anonymous-to-registered purchase transfers with the existing RevenueCat configuration; no store/project credentials or mappings have been invented.

### Subscription compatibility

`POST /api/subscription` accepts the old request shape but ignores client-supplied plan, price and expiry as proof of payment. It verifies the authenticated user's entitlement server-to-server and updates one `store_verified` record. Without configuration it returns 503 and grants nothing. A missing/expired entitlement returns 403. Store syncs have amount zero: do not treat them as recorded cash revenue.

Existing legitimate/manual subscriptions are preserved. Previously client-created rows are also not silently deleted: review them separately with purchase records before making any decision. `GET /api/subscription` revalidates active `store_verified` subscriptions when configured, and revocation affects only those rows. Upstream outages keep the last verified grant until its known expiry.

Existing 80-character bearer tokens remain valid and migrate to SHA-256 digests on use. New tokens are stored only as digests. Logout revokes both representations. Token lifetime was deliberately not shortened; a TTL/refresh-token rollout needs a separate client-compatible migration. Database rollback to the old unhashed-token implementation after digest migration would log migrated users out; retain the new authentication reader during any application rollback.

Rate limiting is database shared across serverless instances: 5 OTP requests per identity per 10 minutes, 15 other auth attempts per identity per 10 minutes, plus 60 requests per trusted Vercel IP per endpoint per 10 minutes. Affected endpoints include request/verify OTP, password login, phone checks, admin login and web account deletion. Tune shared-network limits after staging tests. The non-Vercel fallback uses one local IP bucket; other hosting platforms must supply a trusted IP integration before production use.

Dependencies: Next.js 15.5.27, Firebase Admin 14.5.0 with modular imports, compatible existing Prisma 6, and a PostCSS 8.5.30 override. Updated lockfiles are committed. No known npm advisories remained at verification time.

## Mobile setup

Use the tested Flutter 3.47.7 / Dart 3.13.5 toolchain or validate the release developer's intended toolchain separately. Run `flutter pub get`, `flutter analyze`, and `flutter test` in the bnyad root.

`lib/config/private_keys.dart` now contains build-time configuration only, with no credential defaults:

- `API_BASE_URL`: defaults to the existing documented production API; use a staging URL for QA.
- `RC_ANDROID_PUBLIC_KEY` and `RC_IOS_PUBLIC_KEY`: RevenueCat PUBLIC mobile SDK keys, supplied privately by the release developer.
- `GEMINI_API_KEY`: backend hosting environment ONLY. Never supply it to a Flutter build. See AI_RELEASE_HANDOFF.md for disabled-by-default proxy configuration and manual migration.

A private ignored `release-config.json` can be used with `--dart-define-from-file`; never commit it. Archived upstream source contained credential defaults; rotate any credentials previously exposed in that repository through the responsible provider, coordinating with the existing installed apps.

Restore the existing Firebase native configuration privately:
- Android: `android/app/google-services.json`, matching `com.bnyad.app`.
- iOS: `ios/Runner/GoogleService-Info.plist`, matching `com.nutrify.bnyad`.

These are excluded from this import and from Git. Missing Firebase config disables push in debug; release Android builds require its existing config explicitly.

### Android release developer

Use Java 21 with the existing Gradle 8.14 / Android Gradle Plugin 8.11.1 project. The installed Android Studio bundled Java 25 is incompatible with that Gradle version. For the developer's intended Flutter installation use `flutter config --jdk-dir=PATH_TO_JAVA_21`, or invoke Gradle with an appropriate `JAVA_HOME`.

Supply `android/key.properties` privately, using `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`, pointing to the EXISTING release keystore. Release builds no longer fall back to debug signing. Do not create a new signing identity for the published app. Increment version name/code relative to the currently published release; the imported pubspec version is not evidence of the store's latest version.

The release developer may build `flutter build appbundle --release --dart-define-from-file=release-config.json --build-name=APPROVED_VERSION --build-number=APPROVED_NUMBER` after staging/device QA. This task did not build a signed store release or upload anything.

### iOS release developer

Install a supported Ruby/CocoaPods environment, run `flutter pub get`, then `pod install` in `ios`. The available machine had Xcode 27 but no CocoaPods; unsigned build validation stopped at plugin dependency installation. Some plugins still require CocoaPods even with Swift Package Manager.

Use the existing bundle identifier, Apple team, provisioning profiles and certificates. The common Runner entitlement file now includes the secure-storage package's Keychain Sharing entry. Validate that the resulting signed entitlements preserve the installed app's existing keychain access group. Test update-in-place session retention on a real device. Choose an approved, increasing CFBundleVersion/build number. Signing and store submission belong to the release developer.

## Verification completed and limits

Passed:
- Flutter analysis with no issues.
- 49 Flutter tests: existing nutrition/body-fat/barcode tests plus session persistence, offline/error preservation, revocation, deletion, secure-storage migration, onboarding cache, API profile mapping, account separation, stale-account response isolation, server food-log IDs, failed saves, translation coverage, startup navigation and a compact RTL render.
- Android debug APK build with Java 21.
- Flutter web release build (JavaScript target). A third-party flutter_timezone WebAssembly dry-run warning remains; WebAssembly was not the build target.
- 20 backend security/route regression tests with isolated mocked persistence/upstream responses.
- TypeScript checks, Next.js production build, Prisma schema validation, and npm audit (zero known vulnerabilities).
- No production database URL was used for builds/tests. The build used a deliberately unreachable local placeholder connection.

Not completed:
- Unsigned iOS native compilation: missing CocoaPods.
- Signed Android/iOS release builds, physical-device or simulator reboot/force-stop/update-in-place QA.
- Real OTP, RevenueCat/store payments/restores, APNs/FCM delivery and live AI provider calls, because their private release configuration was not supplied.
- Execution of the SQL against a real staging PostgreSQL database; schema validation and route tests are not a live database migration test.
- Native Sorani speaker sign-off, exhaustive visual testing of every screen/food item/system dialog at every device size.

Use the complete 16-scenario authentication matrix in the original task for release QA: fresh install; successful login; close/reopen; force-stop; reboot; offline reopen; reconnect; revoke/expire a test session; explicit logout/reopen; update an older app; onboarding and saved profile/history retention. Automated tests emulate several of these transitions but do not replace OS/device validation.

## Remaining audit items

- The exact defect in the installed store binaries cannot be established from source alone. Confirmed source causes include early routing before profile/onboarding restoration, missing durable profile fallback, and missing iOS keychain configuration. Secure writes are now read back before sign-in is reported successful; temporary storage/network failures show retry instead of deleting credentials.
- Full stock Material/Cupertino system-dialog localization into Sorani is not provided by the existing hand-written translation architecture. The app catalog is checked, but system-provided dialogs need native-speaker/device review.
- Food/water/meal-plan edits require a successful server response; failures are now visible and preserve prior state. A general durable offline mutation outbox/idempotency rollout remains separate work. Cached reading and session retention work offline.
- Local-only favorites, vitamins, recipes and shopping data are preserved and separated by account; they are not newly migrated into the production API.
- Shared-secret admin authentication remains (with in-memory browser handling, constant-time comparison and login throttling); roles/MFA/audit logs need a separate design.
- Revenue summaries still use the existing floating-point/currency conventions. Historical client-created subscription records require operator review, not automatic removal.
- Legacy Laravel implementations remain reference/optional deployments; this task does not migrate production to Laravel and did not run PHP/Composer tests.
