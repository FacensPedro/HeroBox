"""Regression tests for the Xbox 360 packaging metadata."""
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from configure_xbox_360 import BUNDLE_ID, configure_bundle, read_version


class Xbox360PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / "XeniOS.app"
        self.app.mkdir()
        (self.app / "XeniOS").write_bytes(b"native executable fixture")
        (self.app / "Assets.car").write_bytes(b"asset catalog fixture")
        self.info = self.app / "Info.plist"
        self.info.write_bytes(plistlib.dumps({
            "CFBundleExecutable": "XeniOS",
            "CFBundleIdentifier": "com.xenios",
            "CFBundleShortVersionString": "2.3.3",
            "CFBundleVersion": "11940",
            "LSApplicationQueriesSchemes": ["stikjit"],
        }))
        self.version = self.root / "Version.xcconfig"
        self.version.write_text("MARKETING_VERSION = 0.1.1\nCURRENT_PROJECT_VERSION = 2\n")
        self.assets = self.root / "asset-info.plist"
        self.assets.write_bytes(plistlib.dumps({"CFBundleIcons": {
            "CFBundlePrimaryIcon": {"CFBundleIconName": "AppIcon"}
        }}))

    def test_branding_preserves_entry_point_and_jit(self):
        configure_bundle(self.app, self.version, self.assets)
        info = plistlib.loads(self.info.read_bytes())
        self.assertEqual(info["CFBundleShortVersionString"], "0.1.1")
        self.assertEqual(info["CFBundleVersion"], "2")
        self.assertEqual(info["CFBundleIdentifier"], BUNDLE_ID)
        self.assertEqual(info["CFBundleDisplayName"], "HeroBox")
        self.assertEqual(info["CFBundleExecutable"], "XeniOS")
        self.assertEqual(info["LSApplicationQueriesSchemes"], ["stikjit"])
        self.assertEqual(
            info["CFBundleIcons"]["CFBundlePrimaryIcon"]["CFBundleIconName"],
            "AppIcon",
        )

    def test_rejects_incorrect_version(self):
        self.version.write_text("MARKETING_VERSION = 0.2.0\nCURRENT_PROJECT_VERSION = 2\n")
        with self.assertRaisesRegex(ValueError, "remain at 0.1.1"):
            configure_bundle(self.app, self.version, self.assets)

    def test_rejects_missing_engine(self):
        (self.app / "XeniOS").unlink()
        with self.assertRaisesRegex(ValueError, "Missing original XeniOS executable"):
            configure_bundle(self.app, self.version, self.assets)

    def test_reads_shared_version(self):
        self.assertEqual(read_version(ROOT / "Version.xcconfig"), ("0.1.1", "2"))


if __name__ == "__main__":
    unittest.main()
