"""Offline checks for github-rev updates with one or more fetches."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import update

HEAD = "cf4df59ce91004f7ea39358b1b8ff917d5c329f7"
NEW_HASH = "sha256-" + "A" * 43 + "="
ITEM = {
    "attribute": "whitesur-kde",
    "file": "default.nix",
    "owner": "vinceliuice",
    "repo": "WhiteSur-kde",
    "kind": "github-rev",
    "asset": "",
}
SOURCE = """{
  version = "0-unstable-2024-10-12";
  wallpaper = fetchFromGitHub {
    rev = "eb7b054b1c7c3429965e3b531de2db38e2c83aec";
    hash = "sha256-KBhvsfXLICBwCOL03FHc8Z7gT6hKRL+Dzi1w3ufJFtI=";
  };
  decoration = fetchFromGitHub {
    rev = "36dfbd08b1cdd408c61c986b900b3b45fc98776d";
    hash = "sha256-AzHuJrOwlnpjXE00PqcwHbSVXsZhtFXpVJbpq26hSMU=";
  };
}
"""


class RevUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / "default.nix"
        self.path.write_text(SOURCE)
        root_patch = patch.object(update, "ROOT", self.root)
        root_patch.start()
        self.addCleanup(root_patch.stop)

    def test_rewrites_every_rev_and_hash(self):
        with patch.object(update, "latest_commit", return_value=(HEAD, "2026-08-07")), \
             patch.object(update, "prefetch_github_ref", return_value=NEW_HASH) as prefetch:
            self.assertTrue(update.update_rev(ITEM))
        text = self.path.read_text()
        self.assertEqual(text.count(f'rev = "{HEAD}";'), 2)
        self.assertEqual(text.count(f'hash = "{NEW_HASH}";'), 2)
        self.assertIn('version = "0-unstable-2026-08-07";', text)
        self.assertNotIn("eb7b054", text)
        self.assertNotIn("36dfbd0", text)
        prefetch.assert_called_once_with("vinceliuice", "WhiteSur-kde", HEAD)

    def test_matching_revs_are_left_alone(self):
        text = SOURCE.replace(
            "eb7b054b1c7c3429965e3b531de2db38e2c83aec", HEAD
        ).replace("36dfbd08b1cdd408c61c986b900b3b45fc98776d", HEAD)
        self.path.write_text(text)
        with patch.object(update, "latest_commit", return_value=(HEAD, "2026-08-07")), \
             patch.object(update, "prefetch_github_ref") as prefetch:
            self.assertFalse(update.update_rev(ITEM))
        prefetch.assert_not_called()
        self.assertEqual(self.path.read_text(), text)

    def test_one_rev_still_updates(self):
        self.path.write_text(
            """
            version = "0-unstable-2025-10-24";
            rev = "bbfe078386545688727f44897a7fede8af2c6dda";
            hash = "sha256-oldoldoldoldoldoldoldoldoldoldoldoldold=";
            """
        )
        with patch.object(update, "latest_commit", return_value=(HEAD, "2026-08-07")), \
             patch.object(update, "prefetch_github_ref", return_value=NEW_HASH):
            self.assertTrue(update.update_rev(ITEM))
        text = self.path.read_text()
        self.assertEqual(text.count(f'rev = "{HEAD}";'), 1)
        self.assertIn(f'hash = "{NEW_HASH}";', text)
        self.assertIn('version = "0-unstable-2026-08-07";', text)

    def test_mismatched_rev_and_hash_counts_do_not_rewrite(self):
        bad = SOURCE + '\nhash = "sha256-extraextraextraextraextraextraextraextra=";\n'
        self.path.write_text(bad)
        with patch.object(update, "latest_commit", return_value=(HEAD, "2026-08-07")), \
             patch.object(update, "prefetch_github_ref", return_value=NEW_HASH):
            with self.assertRaises(SystemExit):
                update.update_rev(ITEM)
        self.assertEqual(self.path.read_text(), bad)


if __name__ == "__main__":
    unittest.main()
