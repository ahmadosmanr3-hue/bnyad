#!/usr/bin/env bash
set -euo pipefail

# Complete offline app, real Health Connect. No uninstall, permission grant,
# production connection, release signing, deployment or store submission.
device_id="${1:?Pass the connected Android device serial}"
flutter_bin="${FLUTTER_BIN:-flutter}"
android_sdk_path="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
build_tools_version="${ANDROID_BUILD_TOOLS:-36.0.0}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
: "${JAVA_HOME:?Set JAVA_HOME to an installed JDK compatible with Gradle 8.14 (17 or 21)}"
adb_bin="$android_sdk_path/platform-tools/adb"
aapt_bin="$android_sdk_path/build-tools/$build_tools_version/aapt"
test -x "$adb_bin" && test -x "$aapt_bin"
test "$("$adb_bin" -s "$device_id" get-state)" = device
test "$("$adb_bin" -s "$device_id" shell getprop ro.product.cpu.abi | tr -d '\r')" = arm64-v8a
cd "$repo_root"
"$flutter_bin" pub get
# Flutter writes versionCode/versionName from pubspec and bootstraps the ignored
# Gradle wrapper. Direct Gradle invocation otherwise defaults a fresh clone to 1.
ORG_GRADLE_PROJECT_bnyadOfflinePreview=true "$flutter_bin" build apk --debug \
  --target-platform android-arm64 -t lib/main_android_preview.dart

apk_path="$repo_root/build/app/outputs/flutter-apk/app-debug.apk"
badging="$("$aapt_bin" dump badging "$apk_path")"
permissions="$("$aapt_bin" dump permissions "$apk_path")"
case "$badging" in
  *"package: name='com.bnyad.app.dev'"*) ;;
  *) printf '%s\n' 'Refusing installation: unexpected package ID.' >&2; exit 1 ;;
esac
case "$permissions" in
  *android.permission.INTERNET*) printf '%s\n' 'Refusing offline preview with Internet permission.' >&2; exit 1 ;;
esac
"$adb_bin" -s "$device_id" install -r "$apk_path"
"$adb_bin" -s "$device_id" shell am start -W -n com.bnyad.app.dev/com.bnyad.app.MainActivity
printf '%s\n' 'Open Daily activity and explicitly allow Health Connect Steps. Distance is optional.'
