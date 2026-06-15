# BNYAD

AI-powered nutrition tracking app (Flutter) with trilingual support (English, Arabic, Kurdish Sorani).

## Project structure

```
nutrify/
├── lib/                 Flutter app source
├── android/ ios/ web/   Platform projects
├── assets/images/       App logo
├── test/                Unit tests
├── laravel-backend/     Laravel REST API (migrations, models, controllers, routes)
├── tool/                Dev scripts (food export)
└── firestore.rules      Legacy Firestore rules (kept for reference)
```

## Run the Flutter app

**Requirements:** Flutter SDK 3.11+, Android Studio (for Android), Groq API key.

```powershell
cd nutrify
flutter pub get

# One-time: copy and fill in your keys
copy lib\config\private_keys.example.dart lib\config\private_keys.dart
```

Edit `lib/config/private_keys.dart`:
- Set your **Groq API key**.
- Set `apiBaseUrl` to point at the Laravel API (e.g. `http://10.0.2.2:8000/api` for Android emulator).

```powershell
flutter doctor          # fix anything marked X
flutter devices         # confirm phone/emulator is connected
flutter run
```

**Release APK:**

```powershell
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

## Architecture

The Flutter app talks to a **Laravel REST API** via HTTP (Sanctum bearer tokens).

| Flutter layer | File |
| --- | --- |
| HTTP client | `lib/services/api_service.dart` |
| Auth wrapper | `lib/services/auth_service.dart` |
| State | `lib/providers/app_state.dart` |

Firebase has been fully removed. All data flows through the Laravel API.

## Login

- Auth uses **phone + password + OTP**.
- When the Laravel backend is not deployed, use demo code **`123456`** — the app falls back to local/guest mode.
- **Guest mode** skips sign-in entirely and stores everything in SharedPreferences.

## Backend setup

1. Create a Laravel 11 project and copy the files from `laravel-backend/`.
2. Configure `.env` (database, app key, etc.).
3. Run `php artisan migrate --seed` to create tables and seed food items.
4. Wire an SMS provider in `AuthController::requestOtp` (Twilio, etc.).
5. Point the Flutter app's `apiBaseUrl` at the deployed API.

See `laravel-backend/README.md` for full endpoint docs.

### Food database export

506 food items have been exported to `laravel-backend/database/data/food_items.json`.
To re-export from the Flutter food database:

```powershell
dart run tool/export_foods.dart
```

## Secrets

Never commit `lib/config/private_keys.dart` (gitignored). Only commit `private_keys.example.dart`.

## Tests

```powershell
flutter test
```
