# Isolated iPhone development build

Start from branch `codex/bnyad-stability-2026-10-13`. The `dev` scheme uses
`com.nutrify.bnyad.dev` and the display name **BNYAD Dev**. Production's Runner
scheme, bundle identifier, team and push entitlements are retained. Never install
the Runner/production bundle as a development test.

The development entry point is `lib/main_development.dart`. Configure an approved
isolated staging URL using STAGING_API_BASE_URL and STAGING_ENVIRONMENT_ID as
described in STAGING_SETUP.md. The old hard-coded `.invalid` placeholder is removed.
There is NO production fallback: missing configuration shows a staging setup
screen, and a readiness handshake must pass before the application starts or
credentials can be sent. The known production host and local/insecure URLs are
blocked. Use only fictional test accounts/profile data.

AI is disabled before any AI request; Dart notifications, push and RevenueCat
initialization are skipped, as is native Firebase/push. Live testing must wait
until the isolated backend/database and required approvals are ready.

## Prerequisites

- Flutter 3.47.7, Xcode 27 and CocoaPods 1.17 were used for preparation.
- Pair/trust the phone, enable Developer Mode, and keep it unlocked for install.
- Sign in to Xcode Settings → Apple Accounts. Create an Apple Development
  certificate in Manage Certificates. Do not revoke existing certificates.
- If the certificate is present but invalid, check the Apple WWDR intermediate
  chain at https://developer.apple.com/help/account/certificates/wwdr-intermediate-certificates/.
  Do not use custom “Always Trust” overrides.
- Select your development team only for the `*-dev` configurations, or pass it
  to the command below. The development configurations deliberately do not
  hard-code an individual's team. Never commit signing keys or provisioning profiles.

## Build and install (no store submission)

```sh
flutter pub get
cd ios
pod install
cd ..
flutter analyze
flutter test
flutter build ios --profile --no-codesign --flavor dev -t lib/main_development.dart \
  --dart-define=STAGING_API_BASE_URL=https://ACTUAL_STAGING_HOST/api \
  --dart-define=STAGING_ENVIRONMENT_ID=bnyad-staging-2026-10-14

# Set these to the team and connected phone you verified locally.
export BNYAD_DEV_TEAM='YOUR_TEAM_ID'
export BNYAD_DEV_DEVICE='YOUR_PHONE_UDID'
xcodebuild -workspace ios/Runner.xcworkspace -scheme dev \
  -configuration Profile-dev -sdk iphoneos \
  -destination "id=$BNYAD_DEV_DEVICE" -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$BNYAD_DEV_TEAM" CODE_SIGN_IDENTITY='Apple Development' build
```

Find `TARGET_BUILD_DIR` using the same xcodebuild options with `-showBuildSettings`.
Before installing, inspect `Runner.app/Info.plist` and verify its identifier is
**com.nutrify.bnyad.dev** and display name **BNYAD Dev**. Verify the signature with
`codesign --verify --deep --strict Runner.app`. Then:

```sh
xcrun devicectl device install app --device "$BNYAD_DEV_DEVICE" /absolute/path/to/Runner.app
xcrun devicectl device process launch --device "$BNYAD_DEV_DEVICE" com.nutrify.bnyad.dev
```

Profile mode is intentional: it uses ahead-of-time code and can launch without
an attached Flutter debugger. If iOS asks to trust the developer, approve the
verified account in Settings → General → VPN & Device Management. A free Personal
Team may require renewal after seven days. Installation and startup must be
verified on the device; an unsigned build or passed unit tests do not establish
device success. No production deployment, App Store or TestFlight upload is part
of this procedure.

Firebase's private production plist remains a requirement for the production
build. Development excludes that resource rather than using a fake credential.
The updated Podfile.lock reflects Flutter's Swift Package Manager integration:
compatible plugins resolve through SwiftPM, while the remaining plugins use Pods.
