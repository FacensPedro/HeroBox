#!/usr/bin/env bash
# Build ONE iOS application; never place multiple independently runnable apps
# in a single IPA and claim it is a working multi-console emulator.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
output="$root/build/HeroBox-0.1.1.ipa"
rm -f "$output"

# DukeX provides the currently runnable original Xbox host with the xemu core.
bash "$root/scripts/build-original-xbox.sh"

# This is a developer-only staging IPA until the other native cores have
# been refactored to run inside DukeX's single iOS process.
source="$root/build/HeroBox-0.1.1.ipa"
test -s "$source" || { echo "Missing original Xbox host." >&2; exit 1; }
stage=$(mktemp -d)
trap 'rm -rf "$stage"; rm -f "$output"' EXIT
ditto -x -k "$source" "$stage"
app="$stage/Payload/HeroBox.app"
test -d "$app" || { echo "Missing HeroBox.app." >&2; exit 1; }

# XeniOS is currently a separate UIApplicationMain executable, and Utsuro
# has its own host and JIT lifecycle. Neither is a callable adapter here.
python3 "$root/scripts/verify_unified.py" "$app"

# Validation is a necessary, not sufficient, condition for gameplay. Do not
# publish until the game router and real-device first-frame tests are ready.
echo "Native bridge contract passed, but unified gameplay is not device-validated." >&2
exit 1
