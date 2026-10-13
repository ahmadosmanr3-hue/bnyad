# Firebase setup (push notifications)

Admin notifications reach users **even when the app is closed** via **Firebase Cloud Messaging (FCM)**.

Without Firebase, notifications only appear when the user opens the app.

---

## Step 1 — Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** (e.g. `bnyad-nutrify`)
3. Disable Google Analytics if you don't need it

---

## Step 2 — Add Android app

1. Firebase console → **Add app** → **Android**
2. **Package name:** `com.nutrify.nutrify` (must match exactly)
3. Download **`google-services.json`**
4. Place it here:

```
android/app/google-services.json
```

This file is gitignored — each developer / CI machine needs their own copy.

---

## Step 3 — Enable Cloud Messaging

1. Firebase console → **Build** → **Cloud Messaging**
2. No extra toggle needed on the free Spark plan for basic push

---

## Step 4 — Server key for Vercel (Admin push)

1. Firebase console → **Project settings** → **Service accounts**
2. Click **Generate new private key** → download JSON
3. On **Vercel** → your `nutrify-api` project → **Settings** → **Environment Variables**
4. Add:

| Name | Value |
|------|--------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Paste the **entire JSON file** contents |

5. **Redeploy** the API:

```powershell
cd vercel-api
npx.cmd vercel --prod
```

---

## Step 5 — Rebuild the APK

```powershell
cd nutrify
flutter pub get
flutter build apk --release
```

Share the new APK with users. On first login, the app:

- Requests notification permission
- Subscribes to topic `bnyad_all` (broadcast)
- Sends FCM token to the server

---

## Test push

1. Open the app on a phone and log in (grant notification permission)
2. Open admin panel → **Notifications** → send to **All users**
3. Put the app in background or close it
4. You should see a system notification within a few seconds

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Build fails: missing google-services.json | Add file from Step 2 |
| No push when app closed | Check `FIREBASE_SERVICE_ACCOUNT_JSON` on Vercel + redeploy |
| No push for one user | User must open app once after installing new APK (to register token) |
| Admin shows push error | Read error in API response; check Firebase JSON is valid |

---

## iOS (optional)

1. Add iOS app in Firebase with bundle ID from Xcode
2. Download `GoogleService-Info.plist` → `ios/Runner/`
3. Enable push capability in Xcode + APNs key in Firebase

Android is the primary target for now.
