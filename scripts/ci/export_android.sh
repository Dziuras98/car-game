#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/godot" >&2
  exit 2
fi

GODOT_BIN="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build/android"
APK_PATH="$OUTPUT_DIR/car-game-debug.apk"
LOG_PATH="$OUTPUT_DIR/android-export.log"
VALIDATION_LOG="$OUTPUT_DIR/android-validation.log"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot binary is not executable: $GODOT_BIN" >&2
  exit 1
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
: > "$VALIDATION_LOG"

"$GODOT_BIN" \
  --headless \
  --path "$PROJECT_ROOT" \
  --export-debug "Android" "$APK_PATH" \
  2>&1 | tee "$LOG_PATH"

if [[ ! -s "$APK_PATH" ]]; then
  echo "Android export did not create a non-empty APK: $APK_PATH" >&2
  exit 1
fi

unzip -tq "$APK_PATH" >/dev/null
echo "APK archive integrity: valid" | tee -a "$VALIDATION_LOG"

find_android_tool() {
  local tool_name="$1"
  local discovered=""
  discovered="$(command -v "$tool_name" 2>/dev/null || true)"
  if [[ -n "$discovered" && -x "$discovered" ]]; then
    printf '%s\n' "$discovered"
    return 0
  fi
  if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
    discovered="$(find "$ANDROID_HOME" -type f -name "$tool_name" -perm -111 2>/dev/null | sort -V | tail -n 1)"
    if [[ -n "$discovered" ]]; then
      printf '%s\n' "$discovered"
      return 0
    fi
  fi
  return 1
}

APK_ANALYZER="$(find_android_tool apkanalyzer || true)"
if [[ -z "$APK_ANALYZER" ]]; then
  echo "apkanalyzer was not found; manifest metadata cannot be validated offline." >&2
  exit 1
fi

APPLICATION_ID="$($APK_ANALYZER manifest application-id "$APK_PATH")"
VERSION_NAME="$($APK_ANALYZER manifest version-name "$APK_PATH")"
MIN_SDK="$($APK_ANALYZER manifest min-sdk "$APK_PATH")"
TARGET_SDK="$($APK_ANALYZER manifest target-sdk "$APK_PATH")"
$APK_ANALYZER manifest print "$APK_PATH" > "$OUTPUT_DIR/android-manifest.xml"

{
  echo "application_id=$APPLICATION_ID"
  echo "version_name=$VERSION_NAME"
  echo "min_sdk=$MIN_SDK"
  echo "target_sdk=$TARGET_SDK"
} | tee -a "$VALIDATION_LOG"

if [[ "$APPLICATION_ID" != "com.dziuras98.cargame" ]]; then
  echo "Unexpected Android application id: $APPLICATION_ID" >&2
  exit 1
fi
if [[ "$VERSION_NAME" != "0.1.0" ]]; then
  echo "Unexpected Android version name: $VERSION_NAME" >&2
  exit 1
fi

AAPT_BIN="$(find_android_tool aapt || true)"
if [[ -z "$AAPT_BIN" ]]; then
  echo "aapt was not found; compiled application label cannot be validated." >&2
  exit 1
fi
"$AAPT_BIN" dump badging "$APK_PATH" > "$OUTPUT_DIR/aapt-badging.txt"
grep -q "package: name='com.dziuras98.cargame'" "$OUTPUT_DIR/aapt-badging.txt"
grep -q "application-label:'Car Game'" "$OUTPUT_DIR/aapt-badging.txt"
echo "Compiled application label: Car Game" | tee -a "$VALIDATION_LOG"

APK_SIGNER="$(find_android_tool apksigner || true)"
if [[ -z "$APK_SIGNER" ]]; then
  echo "apksigner was not found; APK signature cannot be verified." >&2
  exit 1
fi
"$APK_SIGNER" verify --verbose --print-certs "$APK_PATH" > "$OUTPUT_DIR/apksigner-verification.txt"
echo "APK signature: valid" | tee -a "$VALIDATION_LOG"

if strings "$APK_PATH" | grep -E 'res://(scripts|scenes)/tests/' >/dev/null; then
  echo "Production Android APK appears to contain test resource paths." >&2
  exit 1
fi
echo "Production APK test-resource scan: clean" | tee -a "$VALIDATION_LOG"

echo "Android debug APK validated: $APK_PATH" | tee -a "$VALIDATION_LOG"
