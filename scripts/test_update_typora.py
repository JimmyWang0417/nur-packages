"""Offline regression checks for the independent Typora plugin update path."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import update


SOURCE = '''{
  typoraVersion = "0.11.18";
  pluginVersion = "1.19.16";
  typora = {
    x86_64-linux = {
      url = "https://example.com/typora_0.11.18_amd64.deb";
      hash = "sha256-ogKTWnVMS3NEzJR9sUPhKIXkpxbKX3D2B/AxjDRrtsY=";
    };
    aarch64-linux = {
      url = "https://example.com/typora_0.11.18_arm64.deb";
      hash = "sha256-Eq1GcyxNp9lBRwHFhP7pQrr4O4kWVWPxi6A9hZ61mtg=";
    };
  };
  plugin = {
    url = "https://github.com/obgnail/typora_plugin/releases/download/1.19.16/typora-plugin@v1.19.16.zip";
    hash = "sha256-bLLZ0dFyChx42qnpPTTwyTR4INkEmwduelSL5aco7+M=";
  };
}
'''
NEW_HASH = "sha256-" + "A" * 43 + "="
ITEM = {
    "attribute": "typora", "file": "sources.nix", "owner": "obgnail",
    "repo": "typora_plugin", "asset": "typora-plugin@v{version}.zip",
}


class TyporaPluginUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / "sources.nix"
        self.path.write_text(SOURCE)
        root_patch = patch.object(update, "ROOT", self.root)
        root_patch.start()
        self.addCleanup(root_patch.stop)

    def release(self, tag="1.20.0", assets=True):
        return {
            "tag_name": tag,
            "assets": [{"name": f"typora-plugin@v{tag.removeprefix('v')}.zip"}] if assets else [],
        }

    def test_updates_only_plugin_and_preserves_architecture_hashes(self):
        for tag in ["1.20.0", "v1.20.0"]:
            with self.subTest(tag=tag):
                self.path.write_text(SOURCE)
                with patch.object(update, "latest_release", return_value=self.release(tag)), \
                     patch.object(update, "prefetch_url", return_value=NEW_HASH) as prefetch:
                    self.assertTrue(update.update_typora_plugin(ITEM))
                result = self.path.read_text()
                before = SOURCE.split("  plugin = {")[0].replace(
                    'pluginVersion = "1.19.16"', 'pluginVersion = "1.20.0"')
                self.assertEqual(result.split("  plugin = {")[0], before)
                self.assertIn(f'/releases/download/{tag}/typora-plugin@v1.20.0.zip', result)
                self.assertIn(NEW_HASH, result)
                prefetch.assert_called_once_with(
                    f"https://github.com/obgnail/typora_plugin/releases/download/{tag}/typora-plugin@v1.20.0.zip")

    def test_unchanged_release_does_not_fetch_or_rewrite(self):
        with patch.object(update, "latest_release", return_value=self.release("1.19.16")), \
             patch.object(update, "prefetch_url") as prefetch:
            self.assertFalse(update.update_typora_plugin(ITEM))
        prefetch.assert_not_called()
        self.assertEqual(self.path.read_text(), SOURCE)

    def test_missing_asset_does_not_rewrite(self):
        with patch.object(update, "latest_release", return_value=self.release(assets=False)), \
             patch.object(update, "prefetch_url") as prefetch:
            with self.assertRaises(SystemExit):
                update.update_typora_plugin(ITEM)
        prefetch.assert_not_called()
        self.assertEqual(self.path.read_text(), SOURCE)

    def test_download_failure_does_not_rewrite(self):
        with patch.object(update, "latest_release", return_value=self.release()), \
             patch.object(update, "prefetch_url", side_effect=RuntimeError("offline")):
            with self.assertRaises(RuntimeError):
                update.update_typora_plugin(ITEM)
        self.assertEqual(self.path.read_text(), SOURCE)

    def test_duplicate_plugin_block_is_rejected(self):
        self.path.write_text(SOURCE + '\n  plugin = {\n  };\n')
        with patch.object(update, "latest_release") as latest:
            with self.assertRaises(SystemExit):
                update.update_typora_plugin(ITEM)
        latest.assert_not_called()

    def test_malformed_tag_is_rejected(self):
        with patch.object(update, "latest_release", return_value=self.release("main")):
            with self.assertRaises(SystemExit):
                update.update_typora_plugin(ITEM)
        self.assertEqual(self.path.read_text(), SOURCE)


if __name__ == "__main__":
    unittest.main()
