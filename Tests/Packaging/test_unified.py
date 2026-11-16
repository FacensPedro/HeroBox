"""Fail closed when an IPA contains fewer than three linked native cores."""
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from verify_unified import (
    BUILD, VERSION, XENIA_ADAPTER, UTSURO_ADAPTER, verify_bundle,
)


class UnifiedRuntimeContractTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.app = Path(temp.name) / "HeroBox.app"
        frameworks = self.app / "Frameworks"
        (frameworks / "MoltenVK.framework").mkdir(parents=True)
        for item in (
            "HeroBox", "Frameworks/libxemu-ios-core.dylib",
            "Frameworks/libslirp.0.dylib", "Frameworks/MoltenVK.framework/MoltenVK",
        ):
            (self.app / item).write_bytes(b"binary fixture")
        (self.app / "Info.plist").write_bytes(plistlib.dumps({
            "CFBundleExecutable": "HeroBox",
            "CFBundleIdentifier": "com.herobox.app",
            "CFBundleShortVersionString": VERSION,
            "CFBundleVersion": BUILD,
        }))

    @staticmethod
    def symbols(path: Path) -> set[str]:
        if path.name == "libxemu-ios-core.dylib":
            return {"_xemu_ios_main"}
        return {XENIA_ADAPTER, UTSURO_ADAPTER}

    def test_full_native_contract(self):
        self.assertEqual(verify_bundle(self.app, self.symbols), [])

    def test_rejects_xbox360_or_xbox_one_executable_without_adapter(self):
        def missing(path: Path) -> set[str]:
            return {"_xemu_ios_main"} if path.suffix == ".dylib" else set()
        errors = verify_bundle(self.app, missing)
        self.assertTrue(any("Xbox 360" in issue for issue in errors))
        self.assertTrue(any("Xbox One" in issue for issue in errors))

    def test_missing_original_xbox_library(self):
        (self.app / "Frameworks/libxemu-ios-core.dylib").unlink()
        self.assertTrue(any("xemu" in issue for issue in verify_bundle(self.app, self.symbols)))

    def test_rejects_wrong_version(self):
        info_path = self.app / "Info.plist"
        info = plistlib.loads(info_path.read_bytes())
        info["CFBundleShortVersionString"] = "0.1.1"
        info_path.write_bytes(plistlib.dumps(info))
        self.assertTrue(any("0.1.0" in issue for issue in verify_bundle(self.app, self.symbols)))


if __name__ == "__main__":
    unittest.main()
