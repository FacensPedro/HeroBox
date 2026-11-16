#!/usr/bin/env python3
"""Verify the original-Xbox-only 0.1.0 release without claiming three cores."""
from __future__ import annotations

import argparse
import plistlib
from pathlib import Path

VERSION = "0.1.0"
BUILD = "1"
BUNDLE_ID = "com.herobox.app"
REQUIRED_FILES = (
    "Frameworks/libxemu-ios-core.dylib",
    "Frameworks/libslirp.0.dylib",
    "Frameworks/MoltenVK.framework/MoltenVK",
    "DukeX-COPYING.txt",
)


def verify_bundle(app: Path) -> list[str]:
    errors: list[str] = []
    info_path = app / "Info.plist"
    try:
        with info_path.open("rb") as stream:
            info = plistlib.load(stream)
    except (OSError, ValueError, TypeError) as error:
        return ["Missing or invalid Info.plist: " + str(error)]
    for key, expected in (
        ("CFBundleIdentifier", BUNDLE_ID),
        ("CFBundleShortVersionString", VERSION),
        ("CFBundleVersion", BUILD),
    ):
        if str(info.get(key, "")) != expected:
            errors.append(key + " must equal " + expected)
    executable = info.get("CFBundleExecutable")
    if not isinstance(executable, str) or not executable or "/" in executable:
        errors.append("Invalid CFBundleExecutable")
    elif not (app / executable).is_file():
        errors.append("Missing native executable: " + executable)
    devices = info.get("UIDeviceFamily")
    if not isinstance(devices, list) or 1 not in devices or 2 not in devices:
        errors.append("The package must target both iPhone and iPad")
    for item in REQUIRED_FILES:
        path = app / item
        if not path.is_file() or path.stat().st_size == 0:
            errors.append("Missing original Xbox runtime file: " + item)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    args = parser.parse_args()
    errors = verify_bundle(args.app)
    if errors:
        for error in errors:
            print("ERROR: " + error)
        return 1
    print("Verified original Xbox 0.1.0 (build 1) package.")
    print("Game boot and Xbox 360 / Xbox One execution are not certified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
