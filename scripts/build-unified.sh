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
trap 'rm -rf "$stage"' EXIT
ditto -x -k "$source" "$stage"
app="$stage/Payload/HeroBox.app"
test -d "$app" || { echo "Missing HeroBox.app." >&2; exit 1; }

# XeniOS is currently a separate UIApplicationMain executable, and Utsuro
# has its own host and JIT lifecycle. Neither is a callable adapter here.
if ! python3 "$root/scripts/verify_unified.py" "$app"; then
  rm -f "$output"
  exit 1
fi

# The output is the single original host, but only after both additional
# native core entry points are genuinely linked into that executable.
# CI validates the minimum binary shape; gameplay still needs device testing.
test -s "$output"
echo "One verified multi-core bundle: $output"
echo "Game launch and first-frame validation still require physical-device tests."
