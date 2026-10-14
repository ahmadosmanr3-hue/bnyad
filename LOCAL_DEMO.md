# BNYAD local browser demo

No backend, database, API credentials, signing or deployment is required. This
reuses the real application screens with an in-browser mock HTTP transport.

## Start on a Mac

From the Flutter project root, using Flutter 3.47.7:

```sh
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8765 --no-web-resources-cdn -t lib/main_demo.dart
```

Keep that terminal open. Open <http://127.0.0.1:8765> in Safari and click **Enter
Demo** in the yellow toolbar. Initial startup includes the existing short splash
animation. No Chrome or Chrome debugging extension is required to use the app.
If port 8765 is busy, select another free port and use that port in the URL.

The web engine, fonts and app assets are served locally with the command above.
The Flutter tooling may fetch package dependencies when preparing the build;
the demo app's API transport itself never makes a real HTTP request.

## Controls and things to try

- Enter Demo: fictional registered user and sample dashboard; no login needed.
- Login / Register: inspect the original authentication screens. Select Iraq
  (+964), use local phone `7700000010` for login or `7700000011` for registration,
  password `demo123`, and verification code `123456`. No SMS is sent and no real
  identity is created. Supplied authentication details are discarded; the
  returned identity is always BNYAD Demo User.
- Onboarding: revisit the original questionnaire, using fictional details only.
- EN / AR / KU: English, Arabic and Kurdish Sorani, including RTL layout.
- Mock premium: toggle local premium authorization; Premium screen opens the
  original paywall. No mobile billing SDK initialization, pricing request or
  real purchase is performed in the browser.
- Phone layout: constrain the app to 390 logical pixels; Full width restores
  the desktop layout. Resize Safari for additional responsive checks.
- Reset sample data: discard only this demo's namespace and restore fixtures.

Food search uses the bundled database. Add/remove foods and meals, change water,
record weight, edit the profile/settings, and explore shopping lists, templates
and nutrition history. Changes and the fictional session survive a refresh in
the same browser and origin (host/port). Private browsing/storage clearing may
discard them. The sample contains seven days of food/water and fourteen days of
weight history. The nutrition values are illustrative estimates.

Daily meal generation/regeneration, recipe generation, shopping suggestions,
food-photo and fridge-photo screens receive fixed, trilingual **simulated**
responses, not Gemini results. Use a non-sensitive sample photo with the gallery
picker; it stays in the browser, is not actually recognized and is not retained
by the mock API. Ingredient inputs, allergies and preferences do not customize
the fixed fixtures. Do not treat the demo as food/allergen or medical advice.
The sample day plan is illustrative, not a prescription matching macro targets.
No weekly meal-plan feature is added.

## Safety and limitations

- Default `lib/main.dart` and the existing development entrypoint do not import
  the demo. There is no `DEMO_MODE` production flag.
- `lib/main_demo.dart` checks for **debug + web + loopback host** before creating
  any services. Release/profile builds and remote hosts display a disabled
  message, never the application or mock authentication. Service constructors
  also reject non-debug builds. Never release this entrypoint.
- All demo auth/fixtures/storage are under `lib/demo/`. SharedPreferences uses
  a separate `bnyad_demo.` prefix; real app secure storage is not read.
- A mock client intercepts API and barcode-provider requests. Unknown routes
  fail locally; there is no fallback to production or to a real HTTP transport.
- External links (including production legal pages and store links) are
  disabled. Push notifications and mobile purchases are unavailable on web.
- Simulated AI consent is local only. Google receives nothing. The existing
  privacy/paywall UI is for inspection, not verification of external services.
- Barcode camera behavior varies by Safari/browser permission support; external
  barcode databases are intentionally blocked. Use manual food search instead.
- Photo body-fat AI is deliberately unavailable rather than fabricating a body
  measurement. Existing non-photo calculations/screens can still be inspected.
- SMS delivery, backend authentication/security, subscriptions, AI recognition,
  production data access and server sync have **not** been tested end-to-end by
  this demo. Nothing is deployed or published.

No environment variables or database migrations are needed for this demo.
`url_launcher_platform_interface` is now a direct dependency (same already-locked
2.3.2 version) solely to provide the isolated external-link blocker.

## Automated checks

```sh
flutter analyze
flutter test
```

`test/demo_mode_test.dart` covers entrypoint isolation, release/host guards,
fake login/OTP, persisted food/water/profile/weight/meal/session data, transport
blocking, trilingual fixture parsing, local premium/consent enforcement and the
external-link blocker. Existing production-focused tests still run unchanged.

For the release developer: pull the branch and build from the normal production
entrypoint (`lib/main.dart`) with the approved production configuration. Do not
use `lib/main_demo.dart`, demo fixtures or the local server as a release target.
