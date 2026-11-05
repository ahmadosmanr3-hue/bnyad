#!/usr/bin/env bash
set -euo pipefail
device="${1:?Pass the connected Samsung serial}"
config="${2:?Pass the absolute public mobile-public.json path}"
sdk="${ANDROID_SDK_ROOT:?Set the installed Android SDK path}"
: "${JAVA_HOME:?Use the existing Java 21 installation}"
[[ "$config" = /* && -f "$config" ]]
cd "$(dirname "$0")/.."
node - "$config" <<'NODE'
const fs=require('node:fs'),{X509Certificate}=require('node:crypto');
const v=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
if(Object.keys(v).sort().join(',')!=='LOCAL_API_BASE_URL,LOCAL_CA_DER_BASE64'||!new X509Certificate(Buffer.from(v.LOCAL_CA_DER_BASE64,'base64')).ca)process.exit(2);
NODE
env ORG_GRADLE_PROJECT_bnyadLocalBackend=true flutter build apk --debug \
  -t lib/main_android_local_backend.dart --dart-define-from-file="$config"
apk=build/app/outputs/flutter-apk/app-debug.apk
manifest="$sdk/build-tools/36.0.0/aapt"
badging="$("$manifest" dump badging "$apk")"
[[ "$badging" == *"package: name='com.bnyad.app.dev'"* && "$badging" == *application-debuggable* ]]
"$sdk/platform-tools/adb" -s "$device" install -r "$apk"
"$sdk/platform-tools/adb" -s "$device" shell am start -W -n com.bnyad.app.dev/com.bnyad.app.MainActivity
printf '%s\n' 'Complete BNYAD Dev installed separately. Private authenticated backend; AI mocked; real Health Connect only.'
