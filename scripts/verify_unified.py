#!/usr/bin/env python3
"""Reject a fake unified IPA unless three native, callable cores are linked."""
from __future__ import annotations

import argparse
import plistlib
import subprocess
from pathlib import Path
from typing import Callable

VERSION = "0.1.1"
BUILD = "2"
BUNDLE_ID = "com.facenspedro.herobox"
XENIA_ADAPTER = "_herobox_xenia_launch"
UTSURO_ADAPTER = "_herobox_utsuro_launch"


def exported_symbols(binary: Path) -> set[str]:
    result = subprocess.run(
        ["xcrun", "nm", "-g", str(binary)],
        text=True, capture_output=True, check=False,
    )
    if result.returncode:
        raise RuntimeError("Symbol scan failed for " + binary.name + ": " + result.stderr)
    return {line.split()[-1] for line in result.stdout.splitlines()
            if line.strip() and line.split()[-1].startswith("_")}


def verify_bundle(
    app: Path, symbols: Callable[[Path], set[str]] = exported_symbols
) -> list[str]:
    errors: list[str] = []
    info_file = app / "Info.plist"
    if not info_file.is_file():
        return ["Missing app Info.plist"]
    try:
        with info_file.open("rb") as handle:
            info = plistlib.load(handle)
    except (OSError, TypeError, ValueError) as error:
        return ["Invalid Info.plist: " + str(error)]

    for key, expected in (
        ("CFBundleIdentifier", BUNDLE_ID),
        ("CFBundleShortVersionString", VERSION),
        ("CFBundleVersion", BUILD),
    ):
        if str(info.get(key, "")) != expected:
            errors.append(key + " must equal " + expected)

    name = info.get("CFBundleExecutable")
    if not isinstance(name, str) or not name:
        return errors + ["Missing CFBundleExecutable"]
    host = app / name
    if not host.is_file():
        return errors + ["Missing host Mach-O executable"]

    root = app / "Frameworks"
    xemu = root / "libxemu-ios-core.dylib"
    if not xemu.is_file():
        errors.append("Missing original Xbox xemu runtime shared library")
    else:
        try:
            if "_xemu_ios_main" not in symbols(xemu):
                errors.append("Missing original Xbox xemu_ios_main export")
        except RuntimeError as error:
            errors.append(str(error))
    for dependency in ("libslirp.0.dylib", "MoltenVK.framework/MoltenVK"):
        if not (root / dependency).is_file():
            errors.append("Missing original Xbox native dependency: " + dependency)
    try:
        host_exports = symbols(host)
    except RuntimeError as error:
        return errors + [str(error)]
    if XENIA_ADAPTER not in host_exports:
        errors.append("Missing callable Xbox 360 XeniOS in-process adapter")
    if UTSURO_ADAPTER not in host_exports:
        errors.append("Missing callable Xbox One Utsuro/FEX in-process adapter")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    args = parser.parse_args()
    errors = verify_bundle(args.app)
    if errors:
        for error in errors:
            print("ERROR: " + error)
        print("Refusing to produce a misleading three-console IPA.")
        return 1
    print("Native symbols found; game boot and first-frame tests are still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
