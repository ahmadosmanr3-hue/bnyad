# Sorani localization repair — release/developer handoff

Branch: codex/bnyad-stability-2026-10-13. See KURDISH_LOCALIZATION_AUDIT.md for verified results and remaining manual QA.

## Safety and dependencies

- No production deployment, database migration, store upload, purchase or real-account test was performed.
- Native health bridges/calculations, calorie/macro formulas, authentication and premium entitlements are unchanged. Numeric input normalization only converts digit/decimal representations before existing validation.
- Flutter adds flutter_localizations from the installed Flutter SDK; pubspec.lock includes its transitive intl dependency. Run flutter pub get. No new environment variables or paid credentials.
- Main uses the canonical Flutter locale ckb and accepts persisted/internal ku. Both remain supported; no user-data migration.
- Sorani Material/Cupertino/Widgets text is app-owned because the installed Flutter SDK has no built-in ckb delegate. Review this vocabulary with a native Sorani speaker and check SDK additions when upgrading Flutter.
- Arabic/Sorani reminder entry accepts localized digits in a 24-hour Material dialog, with access to the standard clock dial. English retains the existing Flutter picker. This narrowly replaces Flutter's ASCII-only text parser; saved reminder times and scheduling semantics are unchanged.
- Android's separate app-owned localization channel saves only the language for Health Connect rationale text. OS permission chrome still follows the device/per-app OS language.
- Existing notification channel IDs, sounds and user preferences are retained. Names/descriptions and pending meal/supplement/digest text update when the app language changes.

## Backend notification migration — NOT APPLIED

Only the existing Next.js notification API/admin form changed. Equivalent source is included in both official repositories.

1. Review and approve the target database, backup and maintenance procedure independently.
2. Before deploying the changed backend, have the release developer apply vercel-api/prisma/notification_translations.sql to that approved database.
3. The SQL adds a nullable JSONB translations column; it does not rewrite notification messages or user records. It uses IF NOT EXISTS to permit safe reapplication.
4. Run the backend's existing dependency install/Prisma generation and build steps. Prisma generation/build do not apply this SQL.
5. Deploy only through the release developer's authorized process. Do not run db push blindly against production.
6. Test against an isolated approved database first. This task used mocked Prisma methods and did not validate the migration against a live database.

Old clients continue receiving plain title/body. Old notification requests remain valid. The updated admin form optionally accepts English, Arabic and Sorani authored versions; when enabled all three are required. The API validates field types, limits and locale keys before writing.

Optional authenticated admin POST /api/admin/notifications fields:

    {
      "title": "English fallback title",
      "body": "English fallback body",
      "translations": {
        "en": {"title": "Reminder", "body": "Review your daily plan."},
        "ar": {"title": "تذكير", "body": "راجع خطتك اليومية."},
        "ckb": {"title": "بیرهێنانەوە", "body": "پلانی ڕۆژانەت بپشکنە."}
      }
    }

The legacy ku key is accepted instead of ckb, not alongside it. Recipient profile language selects the push text. The inbox returns translated title/body plus the authored map so cached messages update on language switching. Do not use real recipients to test this.

Historical single-language admin content, user-entered names, product brands and legacy AI text are preserved. There is no automatic translation service and no Gemini activation.

## Local verification and release QA

- Run Flutter analysis and the full Flutter test suite.
- Optional repeatable screenshots: flutter test --no-pub tool/localization_visual_test.dart. This opt-in harness mounts existing widgets with fictional services, asserts no captured rendering exceptions, and writes EN/AR/Sorani PNGs and render-results.json under build/localization-evidence. It is not a browser/native-device or live AI test.
- Backend: npm test, npm run typecheck, npm run build from vercel-api.
- Browser preview: the existing localhost development preview must be restarted for the new SDK localization dependency. Use the existing development-only main_demo.dart entry point. Never enable that entry point in release.
- Android: build the existing offline development variant with the installed compatible JDK and bnyadOfflinePreview=true. It keeps com.bnyad.app.dev and removes INTERNET. Do not overwrite com.bnyad.app.
- iOS: use the existing dev scheme and main_iphone_preview.dart. Unsigned compile checks are not installation, signing, permission or HealthKit tests. Existing App Store and Health Test installations must be preserved.
- Gemini stays disabled in local/native offline previews. Live AI Sorani quality remains unverified.
- Verify actual native permissions, accessibility, device font fallback, notification delivery/locale switching and store sandbox labels manually before release. OS- or store-controlled dialogs may not support Sorani.
