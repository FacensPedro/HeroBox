#!/usr/bin/env bash
# Package the pinned XeniOS ARM64 Xbox 360 runtime as a HeroBox iOS edition.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
source_revision=77cc1358b71ec268a7fa5792c44d87f0c09a216a
source_repo=https://github.com/xenios-jp/XeniOS.git
release_url=https://github.com/xenios-jp/XeniOS/releases/download/release-v2.3.3-build-11940/xenios_ios_iphone_ipad.ipa
release_sha256=de943a84026d0d93ebd059843e1496080dde0b2761a285c76ff5a6f0474cf158

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Building the iOS runtime requires macOS." >&2
  exit 1
fi
for tool in curl git ditto xcrun python3 shasum codesign plutil; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$root/build" "$work/unpacked" "$work/compiled"
curl --fail --location --retry 3 --retry-delay 3 \
  "$release_url" --output "$work/xenios.ipa"
printf '%s  %s\n' "$release_sha256" "$work/xenios.ipa" | shasum -a 256 --check

ditto -x -k "$work/xenios.ipa" "$work/unpacked"
app=$(find "$work/unpacked/Payload" -mindepth 1 -maxdepth 1 -type d -name '*.app' -print -quit)
bundle_count=$(find "$work/unpacked/Payload" -mindepth 1 -maxdepth 1 -type d -name '*.app' | wc -l | tr -d '[:space:]')
if [[ -z "$app" || "$bundle_count" != 1 ]]; then
  echo "Expected exactly one app in the pinned XeniOS IPA." >&2
  exit 1
fi
entry=$(python3 - "$app/Info.plist" <<'PY'
import plistlib
import sys
with open(sys.argv[1], "rb") as handle:
    info = plistlib.load(handle)
print(info["CFBundleExecutable"])
PY
)
test -f "$app/$entry"
xcrun lipo "$app/$entry" -verify_arch arm64

# Rebuild XeniOS's complete source asset catalog with HeroBox icons, retaining
# the upstream image assets needed by the in-game UI.
git init -q "$work/source"
git -C "$work/source" sparse-checkout init --cone
git -C "$work/source" sparse-checkout set assets/apple/XeniOSAssets.xcassets
git -C "$work/source" fetch -q --depth 1 "$source_repo" "$source_revision"
git -C "$work/source" checkout -q --detach FETCH_HEAD
catalog="$work/source/assets/apple/XeniOSAssets.xcassets"
icon="$root/App/HeroBoxAssets.xcassets/HeroBoxIcon.appiconset/HeroBox.png"
test -f "$icon"
test -f "$catalog/AppIcon.appiconset/Contents.json"
for icon_set in "$catalog"/AppIcon*.appiconset; do
  while IFS= read -r -d '' file; do
    cp "$icon" "$file"
  done < <(find "$icon_set" -maxdepth 1 -type f -name '*.png' -print0)
done
xcrun actool "$catalog" \
  --compile "$work/compiled" --platform iphoneos \
  --minimum-deployment-target 18.0 \
  --target-device iphone --target-device ipad \
  --app-icon AppIcon --include-all-app-icons \
  --output-partial-info-plist "$work/asset-info.plist" \
  --output-format human-readable-text
test -s "$work/compiled/Assets.car"
cp "$work/compiled/Assets.car" "$app/Assets.car"
python3 "$root/scripts/configure_xbox_360.py" \
  "$app" "$root/Version.xcconfig" "$work/asset-info.plist"

mkdir -p "$app/ThirdParty"
test -f "$work/source/LICENSE"
cp "$work/source/LICENSE" "$app/ThirdParty/XeniOS-LICENSE.txt"
cat > "$app/ThirdParty/XeniOS-PROVENANCE.txt" <<EOF
HeroBox Xbox 360 runtime
HeroBox version: 0.1.0 (1)
Core project: XeniOS (BSD-3-Clause)
Source: https://github.com/xenios-jp/XeniOS
Pinned upstream source commit: $source_revision
Pinned upstream release: release-v2.3.3-build-11940
Pinned upstream IPA SHA-256: $release_sha256
The official ARM64 core executable is unchanged. Its app metadata, icon
catalog and signing envelope are adapted for HeroBox. Upstream credits remain.
No copyrighted Xbox firmware or commercial game files are bundled.
EOF

bundle="$work/unpacked/Payload/HeroBox.app"
if [[ "$app" != "$bundle" ]]; then
  mv "$app" "$bundle"
fi

# Preserve the original iOS runtime's requested permissions (including
# XeniOS's debugging memory limit) and merge HeroBox Memory+ permissions.
test -f "$work/source/xenia_ios.entitlements"
python3 - "$work/source/xenia_ios.entitlements" "$root/HeroBox.entitlements" "$work/combined.entitlements" <<'PY'
import plistlib
import sys
from pathlib import Path
original, herobox, output = map(Path, sys.argv[1:])
with original.open("rb") as handle:
    requested = plistlib.load(handle)
with herobox.open("rb") as handle:
    requested.update(plistlib.load(handle))
with output.open("wb") as handle:
    plistlib.dump(requested, handle)
PY

# Verify an ad-hoc signed IPA; final sideloading requires device signing.
shopt -s nullglob
for nested in "$bundle"/Frameworks/*.dylib "$bundle"/Frameworks/*.framework; do
  codesign --force --sign - "$nested"
done
for extension in "$bundle"/PlugIns/*.appex "$bundle"/Extensions/*.appex; do
  codesign --force --sign - "$extension"
done
shopt -u nullglob
codesign --force --sign - --entitlements "$work/combined.entitlements" "$bundle"
codesign --verify --deep --strict "$bundle"

plist="$bundle/Info.plist"
[[ "$(plutil -extract CFBundleShortVersionString raw "$plist")" == "0.1.0" ]]
[[ "$(plutil -extract CFBundleVersion raw "$plist")" == "1" ]]
[[ "$(plutil -extract CFBundleIdentifier raw "$plist")" == "com.herobox.app.xbox360" ]]
test -s "$bundle/Assets.car"
test -f "$bundle/$entry"
output="$root/build/HeroBox-0.1.0-Xbox360.ipa"
rm -f "$output"
(cd "$work/unpacked" && ditto -c -k --sequesterRsrc --keepParent Payload "$output")
test -s "$output"
echo "Packaged $output with the pinned XeniOS ARM64 Xbox 360 core."
