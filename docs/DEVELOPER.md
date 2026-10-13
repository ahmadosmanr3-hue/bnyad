# BNYAD — Developer guide

Start here if you are joining the project.

## What this repo is

| Part | Folder | What it does |
|------|--------|--------------|
| **Flutter app** | `lib/`, `android/`, `ios/` | Mobile app (EN / AR / Kurdish Sorani) |
| **Live API + Admin** | `vercel-api/` | Next.js on Vercel + Neon Postgres — **production backend** |
| **Laravel API (alt)** | `bnyad-api/` | Full Laravel 12 — optional deploy on Railway/Render |
| **Laravel snippets** | `laravel-backend/` | Legacy reference only |

**Production API:** `https://nutrify-api-lovat.vercel.app/api`
**Admin panel:** `https://nutrify-api-lovat.vercel.app/admin`

---

## Quick start (Flutter)

### 1. Requirements

- Flutter SDK 3.11+
- Android Studio (for APK)
- Groq API key (AI features)
- Firebase project (push notifications — see [FIREBASE_SETUP.md](./FIREBASE_SETUP.md))

### 2. Config

```powershell
cd nutrify
flutter pub get
copy lib\config\private_keys.example.dart lib\config\private_keys.dart
```

Edit `lib/config/private_keys.dart`:

- `groqApiKey` — from [console.groq.com](https://console.groq.com)
- `apiBaseUrl` — `https://nutrify-api-lovat.vercel.app/api`

### 3. Firebase (required for push notifications)

Copy your `google-services.json` to `android/app/google-services.json`.
Full steps: **[docs/FIREBASE_SETUP.md](./FIREBASE_SETUP.md)**

### 4. Run / build

```powershell
flutter doctor
flutter run
flutter build apk --release
```

APK output: `build\app\outputs\flutter-apk\app-release.apk`

### 5. Login (demo)

- Phone: any valid number (e.g. `+9647XXXXXXXX`)
- OTP: **`123456`** (while API `APP_ENV=development`)
- Password: at least 6 characters

---

## Backend (Vercel API)

All deploy steps: **`vercel-api/VERCEL.md`**

### Env vars on Vercel

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Neon Postgres connection string |
| `APP_ENV` | `development` = demo OTP `123456` |
| `SETUP_SECRET` | One-time food seed (`POST /api/setup`) |
| `ADMIN_SECRET` | Admin panel password |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Admin JSON for push notifications |

### Redeploy after code changes

```powershell
cd vercel-api
npx.cmd vercel --prod
```

---

## Admin panel

URL: `/admin` on your Vercel domain.

| Tab | Use |
|-----|-----|
| **Dashboard** | Users, revenue, **Nasr 60% / Ahmad 40%** split |
| **Users** | Phone numbers, premium status, days left |
| **Subscriptions** | Record a sale → unlocks premium in the app |
| **Notifications** | Push to all users or one user by phone |

See **[docs/ADMIN_PANEL.md](./ADMIN_PANEL.md)** for workflow details.

---

## Architecture

```
Flutter app  ──HTTP──►  vercel-api (Next.js)
                            │
                            ├── Neon Postgres (users, logs, subs, notifications)
                            ├── Groq API (AI — called from app directly)
                            └── Firebase FCM (push when admin sends notification)
```

| Flutter file | Role |
|--------------|------|
| `lib/services/api_service.dart` | REST client |
| `lib/services/auth_service.dart` | Phone + OTP login |
| `lib/services/ai_service.dart` | Groq AI |
| `lib/services/push_service.dart` | FCM push registration |
| `lib/providers/app_state.dart` | App state |

---

## Premium / subscriptions

There is no payment gateway yet. Flow:

1. User pays you (cash, transfer, etc.)
2. Admin records subscription in panel (phone + days + amount)
3. App syncs premium from `GET /api/subscription` on launch/resume

---

## Push notifications

| When | How |
|------|-----|
| App open | FCM foreground handler + inbox |
| App in background / closed | FCM system notification (requires Firebase setup) |
| Admin sends | Saved in DB + FCM push |

Users need the **latest APK** with `firebase_messaging` and a valid `google-services.json` build.

---

## GitHub repos

| Repo | Contents |
|------|----------|
| [nutrify](https://github.com/ahmadosmanr3-hue/nutrify) | Full project (app + backend) |
| [bnyad](https://github.com/ahmadosmanr3-hue/bnyad) | Backend only |

---

## Tests

```powershell
flutter test
cd vercel-api
npx tsc --noEmit
```
