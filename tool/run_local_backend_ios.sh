#!/bin/bash
# Complete iPhone-only app; normal backend authentication, native HealthKit.
set -euo pipefail
if [[ $# != 3 || ! "$1" =~ ^[A-Z0-9]{10}$ || ! "$2" =~ ^[A-Fa-f0-9-]+$ || "$3" != /* || ! -f "$3" ]]; then
  echo 'Usage: FLUTTER_BIN=/path/to/flutter bash tool/run_local_backend_ios.sh TEAM_ID DEVICE_UDID /absolute/path/mobile-public.json' >&2
  exit 2
fi
local_team="$1"
local_phone="$2"
local_public_config="$3"
cd "$(dirname "$0")/.."
local_flutter="${FLUTTER_BIN:-flutter}"
# Reject credential-bearing build config. Only a public certificate and LAN URL
# belong on-device; API/session secrets never belong in Dart defines.
node - "$local_public_config" <<'NODE'
const fs = require('node:fs');
const { X509Certificate } = require('node:crypto');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (Object.keys(config).sort().join(',') !== 'LOCAL_API_BASE_URL,LOCAL_CA_DER_BASE64' ||
    typeof config.LOCAL_CA_DER_BASE64 !== 'string' || !/^[A-Za-z0-9+/]+=*$/.test(config.LOCAL_CA_DER_BASE64)) process.exit(2);
if (!new X509Certificate(Buffer.from(config.LOCAL_CA_DER_BASE64, 'base64')).ca) process.exit(2);
NODE
"$local_flutter" pub get
"$local_flutter" build ios --profile --config-only --no-codesign --flavor dev -t lib/main_local_backend.dart --dart-define-from-file="$local_public_config"
xcodebuild -quiet -workspace ios/Runner.xcworkspace -scheme dev -configuration Profile-dev \
  -destination "id=$local_phone" -derivedDataPath build/local-iphone \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  "DEVELOPMENT_TEAM=$local_team" CODE_SIGN_STYLE=Automatic \
  BNYAD_DEVELOPMENT_BUNDLE_ID=com.nutrify.bnyad.dev \
  BNYAD_DEVELOPMENT_INFO_PLIST=Runner/LocalBackend-Info.plist \
  FLUTTER_TARGET=lib/main_local_backend.dart build
local_app=build/local-iphone/Build/Products/Profile-dev-iphoneos/Runner.app
[[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$local_app/Info.plist")" == com.nutrify.bnyad.dev ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print BNYADLocalBackend' "$local_app/Info.plist")" == true ]]
codesign --verify --deep --strict "$local_app"
xcrun devicectl device install app --device "$local_phone" "$local_app"
xcrun devicectl device process launch --device "$local_phone" com.nutrify.bnyad.dev
