"""Brand the XeniOS iOS runtime as a HeroBox 0.1.0 Xbox 360 edition.

The pinned ARM64 core executable is retained without binary modification.
"""
from __future__ import annotations
import plistlib
import re
import sys
from pathlib import Path

BUNDLE_ID = "com.facenspedro.herobox.xbox360"


def read_version(path: Path) -> tuple[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line or line.lstrip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    version = values.get("MARKETING_VERSION", "")
    build = values.get("CURRENT_PROJECT_VERSION", "")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("Invalid marketing version in Version.xcconfig")
    if not build.isdigit():
        raise ValueError("Invalid build number in Version.xcconfig")
    return version, build


def configure_bundle(app: Path, version_config: Path, assets_plist: Path) -> None:
    info_path = app / "Info.plist"
    with info_path.open("rb") as handle:
        info = plistlib.load(handle)
    entry = info.get("CFBundleExecutable")
    if not entry or not (app / entry).is_file():
        raise ValueError("Missing original XeniOS executable")
    version, build = read_version(version_config)
    if (version, build) != ("0.1.0", "1"):
        raise ValueError("HeroBox Xbox 360 must remain at 0.1.0 (1)")
    with assets_plist.open("rb") as handle:
        assets = plistlib.load(handle)
    if not (app / "Assets.car").is_file():
        raise ValueError("Missing rebuilt asset catalog")
    if assets.get("com.apple.actool.errors"):
        raise ValueError("Asset catalog contains actool errors")
    info["CFBundleName"] = "HeroBox"
    info["CFBundleDisplayName"] = "HeroBox"
    info["CFBundleIdentifier"] = BUNDLE_ID
    info["CFBundleShortVersionString"] = version
    info["CFBundleVersion"] = build
    # Preserve the icon asset name used by XeniOS, replacing only the artwork.
    for key in ("CFBundleIcons", "CFBundleIcons~ipad", "CFBundleIconName"):
        if key in assets:
            info[key] = assets[key]
    with info_path.open("wb") as handle:
        plistlib.dump(info, handle, sort_keys=True)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: configure_xbox_360.py APP VERSION_XCCONFIG ASSET_INFO_PLIST")
    configure_bundle(*(Path(arg) for arg in sys.argv[1:]))
