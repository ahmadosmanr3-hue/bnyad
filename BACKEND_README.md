# BNYAD Backend

Backend code for the **Nutrify / BNYAD** Flutter app.

## Folders

| Folder | Description | Deploy |
|--------|-------------|--------|
| **`vercel-api/`** | **Live API** — Next.js serverless + Neon Postgres | [Vercel](https://vercel.com) — see `vercel-api/VERCEL.md` |
| **`bnyad-api/`** | Full Laravel 12 API (Sanctum, MySQL) | Railway / Render / Docker |
| **`laravel-backend/`** | Original drop-in Laravel layer (reference) | Not a standalone deploy |

## Live production

- **API URL:** `https://nutrify-api-lovat.vercel.app/api`
- **Health:** `https://nutrify-api-lovat.vercel.app/api/up`
- **Demo OTP:** `123456` (while `APP_ENV=development`)

## Flutter app

The mobile app lives in [nutrify](https://github.com/ahmadosmanr3-hue/nutrify).

Set `lib/config/private_keys.dart`:

```dart
const String apiBaseUrl = 'https://nutrify-api-lovat.vercel.app/api';
```

## Quick deploy (Vercel)

1. Import this repo on Vercel
2. **Root Directory:** `vercel-api`
3. Add env: `DATABASE_URL`, `APP_ENV`, `SETUP_SECRET`
4. Deploy → POST `/api/setup` with `X-Setup-Secret` header to seed foods

See **`vercel-api/VERCEL.md`** for full steps.
