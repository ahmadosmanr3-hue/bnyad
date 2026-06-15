# Deploy BNYAD API on Railway

## Build failed? (most common fixes)

If you see **"Failed to build an image"**:

1. **Root Directory must be `bnyad-api`**  
   Railway → your service → **Settings** → **Root Directory** → type `bnyad-api` → Save → **Redeploy**.

2. **Deploy the latest commit**  
   The API folder was added in commit `Add deployable Laravel API...`.  
   If the deploy shows an older commit (e.g. only MacroCalculationService), click **Redeploy** on the latest `main` commit.

3. **This is not Vercel**  
   The Flutter app cannot be hosted on Vercel. Only `bnyad-api/` (Laravel) goes on Railway.

4. **Set env vars before expecting a healthy deploy**  
   At minimum: `APP_KEY`, `APP_URL`, `DB_CONNECTION=mysql`, and MySQL vars from the Railway database plugin.

---

## What is already in this repo

- Full Laravel 12 app with Sanctum auth, 506 foods seeded, and all nutrition endpoints.
- `railway.toml` runs migrations + seed on each deploy, then starts the server.

## Your steps (≈10 minutes)

### 1. Push this repo to GitHub

Make sure `bnyad-api/` is committed (without `vendor/` or `.env`).

### 2. Create Railway project

1. Go to [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**.
2. Select the `nutrify` repository.
3. Open the service **Settings** → **Root Directory** → set to **`bnyad-api`**.

### 3. Add MySQL

1. In the project, click **+ New** → **Database** → **MySQL**.
2. Open your **web service** → **Variables** → **Add Reference** and link all `MYSQL*` / `DB*` variables from the MySQL service (Railway usually offers a one-click “Add MySQL variables”).

Set these manually:

| Variable | Value |
|----------|-------|
| `APP_NAME` | `BNYAD` |
| `APP_ENV` | `local` *(demo OTP `123456` until SMS is wired)* |
| `APP_DEBUG` | `false` |
| `APP_KEY` | Run locally: `php artisan key:generate --show` and paste |
| `APP_URL` | Your Railway public URL (step 4) |
| `DB_CONNECTION` | `mysql` |

### 4. Public URL

1. Service → **Settings** → **Networking** → **Generate Domain**.
2. Copy the URL, e.g. `https://bnyad-api-production.up.railway.app`.
3. Set `APP_URL` to that URL (no trailing slash).

### 5. Verify deploy

Open `https://YOUR-DOMAIN/up` — should return `{"status":"ok"}`.

Test auth:

```bash
curl -X POST https://YOUR-DOMAIN/api/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"+9647700000001"}'
```

Then verify with code `123456` (while `APP_ENV=local`).

### 6. Point the Flutter app at the live API

Edit `lib/config/private_keys.dart`:

```dart
const String apiBaseUrl = 'https://YOUR-DOMAIN/api';
```

Rebuild the APK:

```bash
flutter build apk --release
```

## Notes

- **Demo login:** OTP is always `123456` when `APP_ENV` is not `production`.
- **Production SMS:** Set `APP_ENV=production` and implement the SMS TODO in `AuthController`.
- **Foods:** Seeded automatically on deploy via `FoodItemSeeder` (506 items).
