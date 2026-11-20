#!/usr/bin/env python3
"""Download one Huawei archive with hdx and curl.

hdx is the Windows build from https://github.com/chawyehsu/hdx (tag v0.1.2).
It reads credentials.json, refreshes that login, asks the download center for
a signed URL, and this script downloads that URL before it expires.

The signed URL and the credential file are never printed. Only archive names
are.
"""

from __future__ import annotations

import argparse
import os
import pty
import re
import select
import subprocess
import sys
import time
import urllib.parse
import urllib.request

URL_RE = re.compile(rb"https://[^\s\x00'\"<>]+")
AGREEMENT = b"Sign the agreement?"


def filename_of(url: str) -> str:
    path = urllib.parse.unquote(urllib.parse.urlparse(url).path)
    return path.rsplit("/", 1)[-1]


def choose(tool: str, urls: list[str]) -> str | None:
    named = [(filename_of(url).lower(), url) for url in urls]
    if tool == "deveco-studio":
        mac = [
            url
            for name, url in named
            if "devecostudio-mac" in name and "arm" not in name
        ]
        if mac:
            return mac[0]
        mac_arm = [url for name, url in named if "devecostudio-mac" in name]
        return mac_arm[0] if mac_arm else None
    if tool == "command-line-tools-for-hmos":
        linux = [
            url
            for name, url in named
            if "commandline-tools-linux-x64" in name
        ]
        return linux[0] if linux else None
    return None


def run_hdx(hdx: str, args: list[str], timeout: int) -> tuple[int, bytes]:
    command = ["wine", hdx, *args] if hdx.lower().endswith(".exe") else [hdx, *args]
    master, slave = pty.openpty()
    proc = subprocess.Popen(
        command,
        stdin=slave,
        stdout=slave,
        stderr=slave,
        close_fds=True,
    )
    os.close(slave)
    captured = bytearray()
    answered = False
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        ready, _, _ = select.select([master], [], [], min(5, remaining))
        if ready:
            try:
                chunk = os.read(master, 65536)
            except OSError:
                chunk = b""
            if not chunk:
                break
            captured += chunk
            if not answered and AGREEMENT in captured:
                os.write(master, b"y\n")
                answered = True
        if proc.poll() is not None and not ready:
            break
    else:
        proc.kill()
        os.close(master)
        raise SystemExit(f"hdx {' '.join(args)} timed out after {timeout}s")
    code = proc.wait()
    os.close(master)
    return code, bytes(captured)


def download(url: str, dest: str) -> None:
    temporary = dest + ".partial"
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "nur-packages-deveco"},
    )
    read = 0
    next_report = 256 * 1024 * 1024
    with urllib.request.urlopen(request, timeout=120) as response, open(temporary, "wb") as output:
        while True:
            block = response.read(1024 * 1024)
            if not block:
                break
            output.write(block)
            read += len(block)
            if read >= next_report:
                print(f"downloaded {read // (1024 * 1024)} MiB", file=sys.stderr)
                next_report += 256 * 1024 * 1024
    os.replace(temporary, dest)
    print(f"saved {filename_of(url)} ({read // (1024 * 1024)} MiB)", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hdx", required=True)
    parser.add_argument("--tool", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()

    if args.refresh:
        code, _captured = run_hdx(args.hdx, ["auth", "refresh"], timeout=180)
        if code != 0:
            raise SystemExit(
                "hdx auth refresh failed. The one-time SMS code cannot be entered here. "
                "On your own machine run `hdx auth login`, then replace the "
                "HDX_CREDENTIALS secret with ~/.config/hdx/credentials.json."
            )
        print("hdx auth refresh finished", file=sys.stderr)

    code, captured = run_hdx(args.hdx, ["-v", "dget", args.tool], timeout=180)
    urls = []
    for match in URL_RE.findall(captured):
        url = match.decode("ascii", "ignore").rstrip(").,]}>\"'")
        if url not in urls:
            urls.append(url)
    names = [filename_of(url) or "(unnamed)" for url in urls]
    print(
        f"hdx dget {args.tool} exit {code}; archive names: {', '.join(names) or '(none)'}",
        file=sys.stderr,
    )
    chosen = choose(args.tool, urls)
    if chosen is None:
        raise SystemExit(
            f"hdx did not return the archive this package builds. "
            f"deveco-studio needs a devecostudio-mac zip and "
            f"command-line-tools-for-hmos needs commandline-tools-linux-x64."
        )
    download(chosen, args.out)
    if code != 0:
        raise SystemExit(code)


if __name__ == "__main__":
    main()
