"""Ensure every HeroBox app target uses the com.herobox namespace."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from configure_xbox_360 import BUNDLE_ID as XBOX360_ID
from verify_original_xbox import BUNDLE_ID as RELEASE_ID
from verify_unified import BUNDLE_ID as UNIFIED_ID

APP_ID = "com.herobox.app"


class BundleIdentifierTests(unittest.TestCase):
    def test_all_primary_targets_have_same_identifier(self):
        self.assertEqual(RELEASE_ID, APP_ID)
        self.assertEqual(UNIFIED_ID, APP_ID)
        self.assertEqual(XBOX360_ID, APP_ID + ".xbox360")

    def test_native_build_and_project_use_identifier(self):
        files = ("project.yml", "scripts/build-original-xbox.sh",
                 "scripts/configure-runtime.py", "scripts/build-xbox-360.sh")
        for name in files:
            with self.subTest(file=name):
                content = (ROOT / name).read_text(encoding="utf-8")
                self.assertIn(APP_ID, content)
                self.assertNotIn("com.facenspedro.herobox", content)

    def test_release_replaces_old_identifier_ipa(self):
        workflow = (ROOT / ".github/workflows/ios.yml").read_text(encoding="utf-8")
        self.assertIn("gh release upload v0.1.0", workflow)
        self.assertIn("--clobber", workflow)
        self.assertIn("CFBundleIdentifier raw", workflow)


if __name__ == "__main__":
    unittest.main()
