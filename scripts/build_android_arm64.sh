#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "Error: Pointlook Chromium Android builds require Linux x86-64." >&2
  exit 1
fi

for tool in gn autoninja; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: '$tool' is missing. Add depot_tools to PATH." >&2
    exit 1
  fi
done

if [[ ! -f DEPS || ! -f chrome/android/BUILD.gn ]]; then
  echo "Error: run this script from the Pointlook Chromium source checkout." >&2
  exit 1
fi

OUT="out/Pointlook"
ARGS='target_os="android" target_cpu="arm64" is_debug=false is_component_build=false symbol_level=1'

echo "== Pointlook Android ARM64 configuration =="
echo "Output: $OUT"
echo "GN args: $ARGS"

gn gen "$OUT" --args="$ARGS"

echo "== Building chrome_public_apk =="
autoninja -C "$OUT" chrome_public_apk

APK="$OUT/apks/ChromePublic.apk"
if [[ ! -s "$APK" ]]; then
  echo "Error: build completed but expected APK was not found: $APK" >&2
  echo "Available APK outputs:" >&2
  find "$OUT" -type f -name '*.apk' -print >&2 || true
  exit 1
fi

mkdir -p "$OUT/artifacts"
cp "$APK" "$OUT/artifacts/Pointlook-Android-ARM64.apk"

echo "== Build completed =="
ls -lh "$OUT/artifacts/Pointlook-Android-ARM64.apk"
