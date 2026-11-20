"""Offline checks for version-only GitHub release updates."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import update

ITEM = {
    "attribute": "deveco-studio",
    "file": "default.nix",
    "owner": "alex3236",
    "repo": "devecostudio-linux",
    "kind": "github-version",
    "asset": "",
}
SOURCE = r"""{
  version = "26.0.0.851";
  ideaVersion = "2026.1.3";
  idea = fetchurl {
    url = "https://download.jetbrains.com/idea/idea-2026.1.3.tar.gz";
    sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  };
}
"""


class ReleaseVersionUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / "default.nix"
        self.path.write_text(SOURCE)
        root_patch = patch.object(update, "ROOT", self.root)
        root_patch.start()
        self.addCleanup(root_patch.stop)

    def test_pkgrel_of_the_same_version_is_left_alone(self):
        with patch.object(update, "latest_release", return_value={"tag_name": "26.0.0.851-3"}), \
             patch.object(update, "prefetch_url") as prefetch:
            self.assertFalse(update.update_release_version(ITEM))
        prefetch.assert_not_called()
        self.assertEqual(self.path.read_text(), SOURCE)

    def test_rewrites_only_the_version_string(self):
        with patch.object(update, "latest_release", return_value={"tag_name": "v26.0.1.100-1"}), \
             patch.object(update, "prefetch_url") as prefetch:
            self.assertTrue(update.update_release_version(ITEM))
        text = self.path.read_text()
        self.assertIn('version = "26.0.1.100";', text)
        self.assertIn('ideaVersion = "2026.1.3";', text)
        self.assertIn("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", text)
        self.assertNotIn("26.0.0.851", text)
        prefetch.assert_not_called()

    def test_a_url_tag_is_refused(self):
        with patch.object(update, "latest_release", return_value={"tag_name": "https://example.invalid/a"}), \
             patch.object(update, "prefetch_url") as prefetch:
            with self.assertRaises(SystemExit):
                update.update_release_version(ITEM)
        prefetch.assert_not_called()
        self.assertEqual(self.path.read_text(), SOURCE)


if __name__ == "__main__":
    unittest.main()
