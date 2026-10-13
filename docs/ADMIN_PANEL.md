# Admin panel guide

**URL:** `https://nutrify-api-lovat.vercel.app/admin`
**Password:** value of `ADMIN_SECRET` on Vercel

---

## Dashboard

- Total users, active premium subscriptions
- Total revenue and this month's revenue
- **Revenue split:** Nasr **60%** / Ahmad **40%** (defined in `vercel-api/lib/admin.ts`)

---

## Users

Lists every registered user:

- Phone number used for login
- Name, join date, language, goal
- Premium status and **days left**
- Total amount paid

Search by name, phone, or email.

### Manage a user (edit / reset / delete)

Click **Manage** on any user row to open their detail panel:

- **Edit** login name, phone, display name, and daily macros (calories / protein / carbs / fat), then **Save changes**.
- **Reset data** — deletes all food logs, water, weight history, and meal plan, and forces the user to **redo onboarding** on next app open. Login and subscription are kept. Use this when a user is stuck with old macros from a previous account.
- **Delete user permanently** — removes the user and all their data (cannot be undone).

> After a reset, the user redoes onboarding the next time they open the app, which regenerates fresh macros.

---

## Subscriptions

When a user pays for premium:

1. Go to **Subscriptions**
2. Enter their **phone number** (same as login)
3. **Days** — e.g. `30` for one month
4. **Amount paid** — e.g. `10`
5. Click **Add subscription**

The app unlocks premium automatically on next open. Renewals **stack** on remaining days.

To cancel: click **Cancel** on an active row.

---

## Notifications

### All users

1. Select **All users**
2. Enter title + message
3. **Send notification**

Users receive a **phone notification** (if Firebase is configured) and the message stays in the in-app inbox (bell icon on dashboard).

### One user

1. Select **One user (by phone)**
2. Enter phone number
3. Send

> User must have opened the **latest APK** at least once so their FCM token is registered.

---

## Env vars checklist (Vercel)

| Variable | Required for |
|----------|--------------|
| `DATABASE_URL` | Everything |
| `ADMIN_SECRET` | Admin login |
| `APP_ENV` | Demo OTP `123456` when `development` |
| `SETUP_SECRET` | Food seed endpoint |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Push when app is closed |

See [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) for Firebase steps.
