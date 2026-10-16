#!/bin/bash
# Local-only diagnostic; no upload, production signing or release archive.
set -euo pipefail
if [[ $# != 2 || ! "$1" =~ ^[A-Z0-9]{10}$ || ! "$2" =~ ^[A-Fa-f0-9-]+$ ]]; then
  echo 'Usage: FLUTTER_BIN=/path/to/flutter bash tool/run_health_test_ios.sh TEAM_ID DEVICE_UDID' >&2
  exit 2
fi
cd "$(dirname "$0")/.."
diagnostic_flutter="${FLUTTER_BIN:-flutter}"
diagnostic_team="$1"
diagnostic_device="$2"
"$diagnostic_flutter" pub get
"$diagnostic_flutter" build ios --profile --config-only --no-codesign --flavor dev -t lib/main_health_test.dart
# Custom Runner-only variables avoid overriding every CocoaPods bundle's plist/ID.
# Automatic provisioning may register only the separate diagnostic identifier/device.
xcodebuild -quiet -workspace ios/Runner.xcworkspace -scheme dev -configuration Profile-dev \
  -destination "id=$diagnostic_device" -derivedDataPath build/healthtest \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  "DEVELOPMENT_TEAM=$diagnostic_team" CODE_SIGN_STYLE=Automatic \
  BNYAD_DEVELOPMENT_BUNDLE_ID=com.nutrify.bnyad.healthtest \
  BNYAD_DEVELOPMENT_INFO_PLIST=Runner/HealthTest-Info.plist \
  FLUTTER_TARGET=lib/main_health_test.dart build
diagnostic_app=build/healthtest/Build/Products/Profile-dev-iphoneos/Runner.app
[[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$diagnostic_app/Info.plist")" == com.nutrify.bnyad.healthtest ]]
xcrun devicectl device install app --device "$diagnostic_device" "$diagnostic_app"
xcrun devicectl device process launch --device "$diagnostic_device" com.nutrify.bnyad.healthtest
