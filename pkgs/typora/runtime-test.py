"""Test the installed launcher using Electron's built-in Node mode."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

PROGRAM = sys.argv.pop(1)


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="typora runtime ")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home with spaces"
        self.home.mkdir()
        self.settings = self.home / ".config/typora_plugin/settings.user.toml"
        self.recorder = Path(self.temp.name) / "record arguments.js"
        self.recorder.write_text(
            "console.log(JSON.stringify({args: process.argv.slice(2), "
            "electron: process.versions.electron}));\n"
        )

    def launch(self, *args, home=None):
        return subprocess.run(
            [PROGRAM, str(self.recorder), *args],
            env={**os.environ, "HOME": str(self.home) if home is None else home,
                 "ELECTRON_RUN_AS_NODE": "1"},
            text=True, capture_output=True, timeout=20,
        )

    def test_first_launch_and_argument_boundaries(self):
        args = ["file with spaces.md", "a; b.md", "$(false).md"]
        result = self.launch(*args)
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["args"], args)
        self.assertEqual(output["electron"], "13.6.1")
        self.assertEqual(self.settings.read_text(), "")
        self.assertEqual(self.settings.stat().st_mode & 0o777, 0o600)

    def test_existing_settings_are_preserved(self):
        self.settings.parent.mkdir(parents=True)
        self.settings.write_text("[global]\nENABLE = false\n")
        self.settings.chmod(0o444)
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.settings.read_text(), "[global]\nENABLE = false\n")

    def test_readable_symlink_is_preserved(self):
        self.settings.parent.mkdir(parents=True)
        target = self.home / "managed.toml"
        target.write_text("# managed\n")
        self.settings.symlink_to(target)
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.settings.is_symlink())
        self.assertEqual(target.read_text(), "# managed\n")

    def test_dangling_symlink_is_rejected(self):
        self.settings.parent.mkdir(parents=True)
        self.settings.symlink_to(self.home / "missing")
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("readable file", result.stderr)
        self.assertTrue(self.settings.is_symlink())

    def test_missing_home_is_rejected(self):
        result = self.launch(home="")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("HOME must be set", result.stderr)


if __name__ == "__main__":
    unittest.main()
