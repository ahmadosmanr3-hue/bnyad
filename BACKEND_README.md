# BNYAD Backend

Backend code for the **Nutrify / BNYAD** Flutter app.  
**Last synced with [nutrify](https://github.com/ahmadosmanr3-hue/nutrify) main:** June 2026

## Folders

| Folder | Description | Deploy |
|--------|-------------|--------|
| **`vercel-api/`** | **Live API** — Next.js serverless + Neon Postgres | [Vercel](https://vercel.com) — see `vercel-api/VERCEL.md` |
| **`bnyad-api/`** | Full Laravel 12 API (Sanctum, MySQL) | Railway / Render / Docker |
| **`laravel-backend/`** | Original drop-in Laravel layer (reference) | Not a standalone deploy |

## Live production

- **API URL:** `https://nutrify-api-lovat.vercel.app/api`
- **Admin panel:** `https://nutrify-api-lovat.vercel.app/admin`
- **Health:** `https://nutrify-api-lovat.vercel.app/api/up`
- **Demo OTP:** `123456` (while `APP_ENV=development`)

### Vercel env vars (production)

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Neon Postgres |
| `APP_ENV` | `development` = demo OTP `123456` |
| `SETUP_SECRET` | One-time food seed (`POST /api/setup`) |
| `ADMIN_SECRET` | Admin panel password |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Push notifications (FCM) |

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
