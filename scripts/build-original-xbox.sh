#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
source_dir="$work/DukeX"
git init -q "$source_dir"
git -C "$source_dir" fetch -q --depth 1 https://github.com/MaftyManicEMU/DukeX.git a28587ab109246645c56e8f62240a835422a9567
git -C "$source_dir" checkout -q --detach FETCH_HEAD
asset_url=https://github.com/MaftyManicEMU/DukeX/releases/download/v1.0.2/DukeX.v1.0.2.ipa
curl --fail --location --retry 3 "$asset_url" -o "$work/runtime.ipa"
unzip -q "$work/runtime.ipa" 'Payload/*.app/Frameworks/*' -d "$work"
frameworks=("$work"/Payload/*.app/Frameworks)
export XEMU_IOS_CORE_DYLIB="${frameworks[0]}/libxemu-ios-core.dylib"
export XEMU_IOS_SLIRP_DYLIB="${frameworks[0]}/libslirp.0.dylib"
export MOLTENVK_FRAMEWORK="${frameworks[0]}/MoltenVK.framework"
for binary in "$XEMU_IOS_CORE_DYLIB" "$XEMU_IOS_SLIRP_DYLIB" "$MOLTENVK_FRAMEWORK/MoltenVK"; do
  xcrun lipo "$binary" -verify_arch arm64
done
app="$source_dir/ios/DukeX/DukeX"
python3 "$root/scripts/configure-original-xbox.py" "$app" "$root"
xcodebuild -project "$source_dir/ios/DukeX/DukeX.xcodeproj" -scheme DukeX \
  -configuration Release -destination 'generic/platform=iOS' -derivedDataPath "$work/derived" \
  -xcconfig "$root/Version.xcconfig" CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.facenspedro.herobox \
  XEMU_IOS_DISPLAY_NAME=HeroBox ASSETCATALOG_COMPILER_APPICON_NAME=HeroBoxIcon build
built="$work/derived/Build/Products/Release-iphoneos/DukeX.app"
mkdir -p "$work/package/Payload" "$root/build"
ditto "$built" "$work/package/Payload/HeroBox.app"
bundle="$work/package/Payload/HeroBox.app"
for item in "$bundle"/Frameworks/*.dylib "$bundle"/Frameworks/*.framework; do
  codesign --force --sign - "$item"
done
cp "$source_dir/COPYING" "$bundle/DukeX-COPYING.txt"
codesign --force --sign - --entitlements "$app/DukeX.entitlements" "$bundle"
codesign --verify --deep --strict "$bundle"
test -f "$bundle/Frameworks/libxemu-ios-core.dylib"
test "$(plutil -extract CFBundleShortVersionString raw "$bundle/Info.plist")" = 0.1.0
(cd "$work/package" && zip -qry "$work/HeroBox.ipa" Payload)
mv "$work/HeroBox.ipa" "$root/build/HeroBox-0.1.0.ipa"
