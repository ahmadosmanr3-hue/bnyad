# BNYAD — mobile application and backend mirror

The existing Flutter application now lives in this repository: `lib/`, `android/`, `ios/`, `assets/`, `fonts/`, `test/`, `web/` and `pubspec.yaml`.

Mobile source was imported with the owner's approval from `ahmadosmanr3-hue/nutrify` at `92b3b6b9ac17358155c5e76c8eed6f851464ab17`. This is the existing application. Original Git history in this repository is preserved.

Read **[RELEASE_HANDOFF.md](RELEASE_HANDOFF.md)** before building or releasing. See **[AUDIT_REPORT.md](AUDIT_REPORT.md)** for findings, files changed and verification limits.

**Current AI integration:** Read [AI_RELEASE_HANDOFF.md](AI_RELEASE_HANDOFF.md). Existing features now use authenticated backend Gemini access, versioned consent, premium checks, quotas and estimated spending controls. AI is disabled until owner-approved server credentials/budget and live staging tests.

## Mobile development

Tested with Flutter 3.47.7 / Dart 3.13.5:

```sh
flutter pub get
flutter analyze
flutter test
```

Build-time configuration uses `API_BASE_URL`, `RC_ANDROID_PUBLIC_KEY` and `RC_IOS_PUBLIC_KEY` only. Never provide `GEMINI_API_KEY` to a mobile build; that key belongs on the backend. Secrets, signing files and native Firebase configuration are not included. Use the published app's existing signing identities and identifiers.

## Backend ownership

`vercel-api/` mirrors the Next.js/Prisma/PostgreSQL backend. The authoritative deployment repository is [bnyad-backend](https://github.com/ahmadosmanr3-hue/bnyad-backend), using `vercel-api` as the deployment root. The documented API/mobile default is `https://nutrify-api-lovat.vercel.app/api`.

`bnyad-api/` is an optional full Laravel deployment. `laravel-backend/` is a reference layer. Production was not migrated to Laravel.

Git-triggered Vercel deployments are disabled in this delivery branch. These changes do not submit a store or production release.
