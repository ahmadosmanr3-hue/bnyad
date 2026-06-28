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
| `ADMIN_SECRET` | password for the admin panel (make up a strong one) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Admin JSON — required for push when app is closed (see `docs/FIREBASE_SETUP.md`) |

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

> Push notifications when the app is closed require Firebase. See **`docs/FIREBASE_SETUP.md`** in the repo root.

---

## Admin panel

Open the panel at:

```
https://YOUR-APP.vercel.app/admin
```

Log in with the value you set for **`ADMIN_SECRET`**. The panel lets you:

- **Dashboard** — total users, active premium, total + monthly revenue, and the
  revenue split between **Nasr (60%)** and **Ahmad (40%)**.
- **Users** — every user with the phone number they logged in with, join date,
  premium status, days left, and total paid. Search by name / phone / email.
- **Subscriptions** — record a sale: enter a user's phone, days, and amount paid.
  This unlocks premium in their app and starts the days-left countdown. Renewals
  stack on top of remaining time. You can also cancel a subscription.
- **Notifications** — send a push to **all users** or **one user** (by phone).
  The app shows it as a phone notification and keeps it in an in-app inbox.

> Revenue split is defined in `lib/admin.ts` (`STOCKHOLDERS`). Change the names
> or percentages there if ownership changes (shares must add up to 1.0).

### How premium works now

There is no payment gateway yet, so **the admin grants premium manually** after a
user pays you (cash / transfer / etc.). The app reads its status from
`GET /api/subscription` on launch and resume, so premium appears automatically.

---

## Notes

- **Vercel free tier** — no sleep like Render; good for API
- **Neon free tier** — 512MB Postgres, enough for this app
- Set `APP_ENV=production` when you wire real SMS (OTP won't be `123456`)
- After deploy, `prisma db push` (in the build) creates the new `subscriptions`
  and `notifications` tables automatically.
