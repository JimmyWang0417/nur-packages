"""Validate the upstream layout and inject the pinned Typora plugin."""

from pathlib import Path
import shutil
import sys


def prepare(app: Path, plugin: Path) -> None:
    windows = [p for p in app.rglob("window.html") if "node_modules" not in p.parts]
    if len(windows) != 1:
        raise ValueError(f"expected one window.html, found {windows}")
    window = windows[0]
    content = window.read_text()
    anchor = '<script src="./appsrc/window/frame.js" defer="defer"></script>'
    entry = '<script src="./plugin/index.js" defer="defer"></script>'
    if content.count(anchor) != 1 or entry in content:
        raise ValueError(f"upstream injection point changed: {window}")
    if not (plugin / "index.js").is_file():
        raise ValueError("plugin archive must contain plugin/index.js")
    shutil.copytree(plugin, window.parent / "plugin")
    window.write_text(content.replace(anchor, anchor + entry))

    # In-place updates cannot modify the immutable Nix store.
    settings = window.parent / "plugin/global/settings/settings.default.toml"
    original = settings.read_text()
    before, separator, updater = original.partition("[updater]\n")
    if not separator:
        raise ValueError("plugin updater configuration changed")
    section, next_section, rest = updater.partition("\n[")
    if section.count("ENABLE = true") != 1:
        raise ValueError("plugin updater ENABLE default changed")
    section = section.replace("ENABLE = true", "ENABLE = false", 1)
    settings.write_text(before + separator + section + next_section + rest)


if __name__ == "__main__":
    prepare(Path(sys.argv[1]), Path(sys.argv[2]))
