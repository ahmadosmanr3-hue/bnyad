# Deploy BNYAD API on Vercel

Laravel **cannot** run on Vercel. This folder is a **Node.js serverless API** that matches the same endpoints your Flutter app already uses.

---

## Step 1 — Free Postgres (Neon)

1. Go to [neon.tech](https://neon.tech) → sign up (free, no card on basic tier)
2. Create a project → copy **Connection string** (PostgreSQL)
   ```
   postgresql://user:pass@host/db?sslmode=require
   ```

---

## Step 2 — Deploy on Vercel

1. Go to [vercel.com](https://vercel.com) → **Add New Project**
2. Import GitHub repo `nutrify`
3. **Root Directory:** `vercel-api`  ← important
4. Framework: **Next.js** (auto-detected)

### Environment variables

| Name | Value |
|------|--------|
| `DATABASE_URL` | Neon connection string |
| `APP_ENV` | `development` *(demo OTP `123456`)* |
| `SETUP_SECRET` | any long random string you make up |

5. Click **Deploy** — wait ~2 min

Your API URL will be like:
```
https://nutrify-xxxx.vercel.app
```

---

## Step 3 — Seed the food database (once)

After deploy succeeds, run in browser or curl:

```bash
curl -X POST https://YOUR-APP.vercel.app/api/setup \
  -H "X-Setup-Secret: YOUR_SETUP_SECRET"
```

This loads 506 foods into Postgres.

---

## Step 4 — Test

```
https://YOUR-APP.vercel.app/api/up
```
→ `{"status":"ok"}`

---

## Step 5 — Flutter app

Edit `lib/config/private_keys.dart`:

```dart
const String apiBaseUrl = 'https://YOUR-APP.vercel.app/api';
```

Rebuild APK:

```powershell
cd c:\Users\damon\Desktop\nutrify
flutter build apk --release
```

Login: OTP **`123456`**

---

## Notes

- **Vercel free tier** — no sleep like Render; good for API
- **Neon free tier** — 512MB Postgres, enough for this app
- Set `APP_ENV=production` when you wire real SMS (OTP won't be `123456`)
