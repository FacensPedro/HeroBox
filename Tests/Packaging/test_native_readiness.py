import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from check_unified_sources import missing_adapters


class NativeAdapterReadinessTests(unittest.TestCase):
    def test_missing_adapters_block_release(self):
        missing = missing_adapters()
        self.assertIn("NativeRuntime/XeniOSAdapter.mm", missing)
        self.assertIn("NativeRuntime/UtsuroAdapter.mm", missing)


if __name__ == "__main__":
    unittest.main()
