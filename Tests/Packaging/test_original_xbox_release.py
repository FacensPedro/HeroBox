"""Regression tests for original Xbox 0.1.0 release packaging."""
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from verify_original_xbox import BUILD, REQUIRED_FILES, VERSION, verify_bundle


class OriginalXboxReleaseTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.app = Path(temporary.name) / "HeroBox.app"
        self.app.mkdir()
        (self.app / "HeroBox").write_bytes(b"arm64 fixture")
        for item in REQUIRED_FILES:
            path = self.app / item
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"fixture")
        self.info = {
            "CFBundleExecutable": "HeroBox",
            "CFBundleIdentifier": "com.facenspedro.herobox",
            "CFBundleShortVersionString": VERSION,
            "CFBundleVersion": BUILD,
            "UIDeviceFamily": [1, 2],
        }
        self.save()

    def save(self):
        (self.app / "Info.plist").write_bytes(plistlib.dumps(self.info))

    def test_release_package(self):
        self.assertEqual(verify_bundle(self.app), [])

    def test_rejects_wrong_version(self):
        self.info["CFBundleShortVersionString"] = "0.1.1"
        self.save()
        self.assertTrue(any("0.1.0" in error for error in verify_bundle(self.app)))

    def test_rejects_missing_core(self):
        (self.app / REQUIRED_FILES[0]).unlink()
        self.assertTrue(any("libxemu" in error for error in verify_bundle(self.app)))

    def test_requires_ipad_support(self):
        self.info["UIDeviceFamily"] = [1]
        self.save()
        self.assertTrue(any("iPad" in error for error in verify_bundle(self.app)))


if __name__ == "__main__":
    unittest.main()
