#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
: "${HUSK_FEX_DIR:?Set HUSK_FEX_DIR to a husk-fex checkout with the hosted JIT hooks}"
export FEXCORE_SRC="$HUSK_FEX_DIR/runtime/sources/fexcore-darwin"
test -f "$FEXCORE_SRC/CMakeLists.txt"
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT
git init -q "$workspace/core"
git -C "$workspace/core" fetch -q --depth 1 https://github.com/Leviidev/Utsuro.git 635721fe00580f668d12bd0cbeb273f1a82e4d12
git -C "$workspace/core" checkout -q --detach FETCH_HEAD
python3 "$root/scripts/configure-runtime.py" "$workspace/core" "$root"
mkdir -p "$root/build"
export DD="$workspace/derived"
bash "$workspace/core/scripts/package_ipa.sh" "$root/build/HeroBox-0.1.1-XboxOne.ipa"
