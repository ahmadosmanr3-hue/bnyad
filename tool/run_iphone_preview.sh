#!/bin/bash
# Complete existing BNYAD UI, local fictional API and real HealthKit.
set -euo pipefail
if [[ $# != 2 || ! "$1" =~ ^[A-Z0-9]{10}$ || ! "$2" =~ ^[A-Fa-f0-9-]+$ ]]; then
  echo 'Usage: FLUTTER_BIN=/path/to/flutter bash tool/run_iphone_preview.sh TEAM_ID DEVICE_UDID' >&2
  exit 2
fi
cd "$(dirname "$0")/.."
preview_flutter="${FLUTTER_BIN:-flutter}"
preview_team="$1"
preview_device="$2"
"$preview_flutter" pub get
"$preview_flutter" build ios --profile --config-only --no-codesign --flavor dev -t lib/main_iphone_preview.dart
xcodebuild -quiet -workspace ios/Runner.xcworkspace -scheme dev -configuration Profile-dev \
  -destination "id=$preview_device" -derivedDataPath build/healthtest \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  "DEVELOPMENT_TEAM=$preview_team" CODE_SIGN_STYLE=Automatic \
  BNYAD_DEVELOPMENT_BUNDLE_ID=com.nutrify.bnyad.dev \
  BNYAD_DEVELOPMENT_INFO_PLIST=Runner/OfflinePreview-Info.plist \
  FLUTTER_TARGET=lib/main_iphone_preview.dart build
preview_app=build/healthtest/Build/Products/Profile-dev-iphoneos/Runner.app
[[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$preview_app/Info.plist")" == com.nutrify.bnyad.dev ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print BNYADOfflinePreview' "$preview_app/Info.plist")" == true ]]
xcrun devicectl device install app --device "$preview_device" "$preview_app"
xcrun devicectl device process launch --device "$preview_device" com.nutrify.bnyad.dev
