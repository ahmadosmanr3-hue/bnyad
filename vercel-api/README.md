# BNYAD API (Vercel)

Production backend for the BNYAD / Nutrify Flutter app.

**Synced with nutrify main:** June 2026

**Live:** `https://nutrify-api-lovat.vercel.app`  
**Admin:** `/admin`  
**Health:** `/api/up`

## Deploy

See **[VERCEL.md](./VERCEL.md)** for full setup (Neon Postgres, env vars, seed).

Quick redeploy:

```powershell
npx.cmd vercel --prod
```

## Structure

```
vercel-api/
├── app/
│   ├── admin/page.tsx          Admin web panel
│   └── api/
│       ├── admin/              Admin APIs (stats, users, subs, notifications)
│       ├── auth/               Phone OTP login
│       ├── fcm-token/          Register device for push
│       ├── subscription/       User premium status
│       ├── notifications/      User notification inbox
│       ├── profile/ logs/ ...  App data endpoints
│       └── setup/              One-time food seed
├── lib/
│   ├── admin.ts                Revenue split (Nasr 60 / Ahmad 40)
│   ├── fcm.ts                  Firebase push sender
│   ├── auth.ts db.ts http.ts
│   └── seedFoods.ts
└── prisma/schema.prisma        Database schema
```

## Environment variables

| Name | Required | Description |
|------|----------|-------------|
| `DATABASE_URL` | Yes | Neon Postgres URL |
| `APP_ENV` | Yes | `development` = OTP `123456` |
| `SETUP_SECRET` | Yes | Protects `POST /api/setup` |
| `ADMIN_SECRET` | Yes | Admin panel password |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | For push | Firebase Admin service account JSON |

## Docs

- [../docs/DEVELOPER.md](../docs/DEVELOPER.md) — full project guide
- [../docs/FIREBASE_SETUP.md](../docs/FIREBASE_SETUP.md) — push notifications
- [../docs/ADMIN_PANEL.md](../docs/ADMIN_PANEL.md) — admin usage
