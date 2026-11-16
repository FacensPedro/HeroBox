#!/usr/bin/env python3
"""Preflight for actual linked native console adapters, not empty placeholder IPAs."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADAPTERS = (
    ROOT / "NativeRuntime" / "XeniOSAdapter.mm",
    ROOT / "NativeRuntime" / "UtsuroAdapter.mm",
)


def missing_adapters() -> list[str]:
    return [str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)\n            for path in ADAPTERS if not path.is_file()]


def main() -> int:
    missing = missing_adapters()
    if missing:
        print("Unified native runtime not ready. Missing source adapters:")
        for path in missing:
            print(" - " + path)
        return 1
    print("Adapter source files exist; full native link and symbol verification are still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
