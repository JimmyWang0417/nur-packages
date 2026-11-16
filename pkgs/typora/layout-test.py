"""Check the resource layout and parse settings with the bundled TOML parser."""

import json
import os
from pathlib import Path
import subprocess
import sys


package = Path(sys.argv[1])
app = package / "lib/typora"
windows = [p for p in app.rglob("window.html") if "node_modules" not in p.parts]
assert len(windows) == 1, windows
assert windows[0].read_text().count("./plugin/index.js") == 1
plugin = windows[0].parent / "plugin"
assert (plugin / "index.js").is_file()

# Upstream uses TOML 1.1, while Python 3.13's tomllib supports TOML 1.0.
# In a renderer Object.hasOwn is provided by upstream's browser polyfills.
parser = plugin / "global/core/lib/smol-toml.js"
settings = plugin / "global/settings/settings.default.toml"
script = (
    "Object.hasOwn = Object.hasOwn || ((o,k) => Object.prototype.hasOwnProperty.call(o,k));"
    "const assert = require('assert');"
    "const toml = require(" + json.dumps(str(parser)) + ");"
    "const settings = toml.parse(require('fs').readFileSync("
    + json.dumps(str(settings)) + ", 'utf8'));"
    "assert.strictEqual(settings.updater.ENABLE, false);"
)
subprocess.run(
    [str(package / "bin/typora"), "-e", script],
    env={**os.environ, "HOME": os.environ["TMPDIR"], "ELECTRON_RUN_AS_NODE": "1"},
    check=True,
)
