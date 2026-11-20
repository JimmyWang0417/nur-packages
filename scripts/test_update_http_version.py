"""Offline checks for http-version updates."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import update

NEW_HASH = "sha256-" + "B" * 43 + "="
ITEM = {
    "attribute": "qoder",
    "file": "default.nix",
    "owner": "",
    "repo": "",
    "kind": "http-version",
    "asset": "",
    "versionUrl": "https://example.invalid/latest.deb",
    "versionHeader": "x-oss-meta-version",
    "fileUrl": "https://example.invalid/releases/{version}/app.deb",
}
SOURCE = r"""{
  version = "0.5.16";
  src = fetchurl {
    url = "https://example.invalid/releases/${version}/app.deb";
    hash = "sha256-V9aAfbHX0E+L3/g9yzZtruzupEJJWsa9STsRtSV2I8Y=";
  };
}
"""


class HttpVersionUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / "default.nix"
        self.path.write_text(SOURCE)
        root_patch = patch.object(update, "ROOT", self.root)
        root_patch.start()
        self.addCleanup(root_patch.stop)

    def test_rewrites_version_and_hash(self):
        with patch.object(update, "latest_http_version", return_value="0.5.17"), \
             patch.object(update, "prefetch_url", return_value=NEW_HASH) as prefetch:
            self.assertTrue(update.update_http_version(ITEM))
        text = self.path.read_text()
        self.assertIn('version = "0.5.17";', text)
        self.assertIn(f'hash = "{NEW_HASH}";', text)
        self.assertNotIn("0.5.16", text)
        prefetch.assert_called_once_with(
            "https://example.invalid/releases/0.5.17/app.deb"
        )

    def test_same_version_is_left_alone(self):
        with patch.object(update, "latest_http_version", return_value="0.5.16"), \
             patch.object(update, "prefetch_url") as prefetch:
            self.assertFalse(update.update_http_version(ITEM))
        prefetch.assert_not_called()
        self.assertEqual(self.path.read_text(), SOURCE)


if __name__ == "__main__":
    unittest.main()
