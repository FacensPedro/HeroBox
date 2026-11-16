import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import check_unified_sources


class NativeAdapterReadinessTests(unittest.TestCase):
    def test_missing_adapters_block_release(self):
        with tempfile.TemporaryDirectory() as temp:
            missing_path = Path(temp) / "XeniOSAdapter.mm"
            with patch.object(check_unified_sources, "ADAPTERS", (missing_path,)):
                missing = check_unified_sources.missing_adapters()
            self.assertEqual(len(missing), 1)
            self.assertTrue(missing[0].endswith("XeniOSAdapter.mm"))

    def test_existing_adapters_pass_preflight(self):
        with tempfile.TemporaryDirectory() as temp:
            xenia = Path(temp) / "XeniOSAdapter.mm"
            utsuro = Path(temp) / "UtsuroAdapter.mm"
            xenia.touch()
            utsuro.touch()
            with patch.object(check_unified_sources, "ADAPTERS", (xenia, utsuro)):
                self.assertEqual(check_unified_sources.missing_adapters(), [])


if __name__ == "__main__":
    unittest.main()
