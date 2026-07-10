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

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot binary is not executable: $GODOT_BIN" >&2
  exit 1
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

ADB_BIN=""
if [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
  ADB_BIN="$ANDROID_HOME/platform-tools/adb"
elif command -v adb >/dev/null 2>&1; then
  ADB_BIN="$(command -v adb)"
fi

if [[ -n "$ADB_BIN" ]]; then
  export ADB_SERVER_SOCKET="tcp:127.0.0.1:5037"
  "$ADB_BIN" start-server >/dev/null
  "$ADB_BIN" devices >/dev/null
else
  echo "adb was not found; Godot export will continue without pre-starting an ADB server." | tee "$OUTPUT_DIR/adb-warning.txt"
fi

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

AAPT_BIN=""
if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/build-tools" ]]; then
  latest_build_tools="$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
  if [[ -x "$latest_build_tools/aapt" ]]; then
    AAPT_BIN="$latest_build_tools/aapt"
  fi
fi

if [[ -n "$AAPT_BIN" ]]; then
  "$AAPT_BIN" dump badging "$APK_PATH" | tee "$OUTPUT_DIR/aapt-badging.txt"
  grep -q "package: name='com.dziuras98.cargame'" "$OUTPUT_DIR/aapt-badging.txt"
  grep -q "application-label:'Car Game'" "$OUTPUT_DIR/aapt-badging.txt"
else
  echo "aapt was not found; archive integrity was checked but manifest metadata was not dumped." | tee "$OUTPUT_DIR/aapt-warning.txt"
fi

if strings "$APK_PATH" | grep -E 'res://(scripts|scenes)/tests/' >/dev/null; then
  echo "Production Android APK appears to contain test resource paths." >&2
  exit 1
fi

echo "Android debug APK validated: $APK_PATH"
