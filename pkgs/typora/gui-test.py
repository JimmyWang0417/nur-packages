"""Open the packaged editor on Xvfb and check plugin initialization."""

import os
from pathlib import Path
import re
import select
import signal
import subprocess
import sys
import tempfile
import time
from xml.sax.saxutils import escape


def stop(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=5)


with tempfile.TemporaryDirectory(prefix="typora-gui-") as temp:
    home = Path(temp)
    runtime = home / "run"
    runtime.mkdir(mode=0o700)
    document = home / "nix-gui-check.md"
    document.write_text("# Nix GUI check\n\nTypora plugin loading.\n")
    # Nix builders do not have the host's /etc/fonts or installed fonts.
    font_config = home / "fonts.conf"
    font_config.write_text(
        '<?xml version="1.0"?><fontconfig><dir>' + escape(sys.argv[2])
        + '</dir><cachedir>' + escape(str(home / "fontcache"))
        + '</cachedir></fontconfig>'
    )
    log_path = home / "typora.log"
    read_fd, write_fd = os.pipe()
    xvfb = subprocess.Popen(
        ["Xvfb", "-displayfd", str(write_fd), "-screen", "0", "1280x900x24",
         "-nolisten", "tcp"],
        pass_fds=(write_fd,), start_new_session=True,
    )
    os.close(write_fd)
    try:
        try:
            assert select.select([read_fd], [], [], 15)[0], "Xvfb did not start"
            display = os.read(read_fd, 32).decode().strip()
            assert display.isdecimal(), "Xvfb did not provide a display number"
        finally:
            os.close(read_fd)
        env = {**os.environ, "HOME": str(home), "DISPLAY": ":" + display,
               "XDG_RUNTIME_DIR": str(runtime), "ELECTRON_ENABLE_LOGGING": "1",
               "FONTCONFIG_FILE": str(font_config), "FONTCONFIG_PATH": str(home)}
        env.pop("ELECTRON_RUN_AS_NODE", None)
        with log_path.open("w") as log:
            # The build environment cannot provide Chromium's user sandbox.
            process = subprocess.Popen(
                [sys.argv[1], "--no-sandbox", "--disable-gpu",
                 "--enable-logging=stderr", str(document)],
                env=env, stdout=log, stderr=log, start_new_session=True,
            )
            try:
                deadline = time.monotonic() + 45
                while time.monotonic() < deadline:
                    assert process.poll() is None, (
                        f"Typora exited before initialization (status {process.returncode})"
                    )
                    content = re.sub(r"\x1b\[[0-9;]*m", "", log_path.read_text())
                    tree = subprocess.run(
                        ["xwininfo", "-root", "-tree"], env=env,
                        text=True, capture_output=True, timeout=5, check=True,
                    ).stdout
                    enabled = re.search(r"\[ enable \] \[ (\d+) \]", content)
                    if (document.name in tree and enabled and int(enabled[1]) > 0
                            and "[ error ] [ 0 ]" in content):
                        print(tree)
                        print("Typora window opened; plugin initialization reported zero errors")
                        break
                    time.sleep(0.5)
                else:
                    raise AssertionError("Typora window or plugin initialization not observed")
            except Exception:
                print(log_path.read_text(), file=sys.stderr)
                raise
            finally:
                stop(process)
    finally:
        stop(xvfb)
