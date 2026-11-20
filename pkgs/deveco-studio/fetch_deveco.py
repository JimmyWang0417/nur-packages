#!/usr/bin/env python3
"""Refresh a local hdx login and record DevEco archives by hash.

The signed download URLs stay in this process. They are not printed, not
written to sources.local.nix, and not committed. The Nix derivation later
reads only the archive name and the flat sha256 from that gitignored file.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import os
import pty
import re
import select
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

URL_RE = re.compile(rb"https://[^\s\x00'\"<>]+")
AGREEMENT = b"Sign the agreement?"
PROMPT = (b"password", b"Password", b"verification code", "验证码".encode())
LOGIN = "run `hdx auth login` on this machine"
NAME_RE = re.compile(r"[A-Za-z0-9._+-]+")
HASH_RE = re.compile(r"sha256-[A-Za-z0-9+/]{43}=")


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


def find_hdx() -> str:
    candidates: list[Path] = []
    override = os.environ.get("HDX", "").strip()
    if override:
        candidates.append(Path(override))
    found = shutil.which("hdx")
    if found:
        candidates.append(Path(found))
    home = Path.home()
    candidates.extend(
        [
            home / ".local/bin/hdx",
            home / ".cargo/bin/hdx",
            home / ".nix-profile/bin/hdx",
        ]
    )
    seen: set[Path] = set()
    for candidate in candidates:
        resolved = candidate.expanduser()
        if resolved in seen:
            continue
        seen.add(resolved)
        if not (resolved.is_file() and os.access(resolved, os.X_OK)):
            continue
        if resolved.name.lower().endswith(".exe"):
            raise SystemExit(
                "Refusing to run a Windows hdx.exe. Put a Linux hdx binary on PATH, "
                "then rerun `nix run .#fetch-deveco`."
            )
        return str(resolved)
    raise SystemExit(
        "hdx is not available. The DevEco fetch runs the hdx package from "
        "this repository; rerun `nix run .#fetch-deveco`."
    )


def credentials_path() -> Path:
    config = os.environ.get("XDG_CONFIG_HOME", "").strip()
    if config:
        return Path(config) / "hdx" / "credentials.json"
    return Path.home() / ".config" / "hdx" / "credentials.json"


def require_credentials() -> None:
    path = credentials_path()
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(LOGIN)


def repo_root() -> Path:
    current = Path.cwd().resolve()
    for candidate in [current, *current.parents]:
        if (candidate / "flake.nix").is_file() and (
            candidate / "pkgs/deveco-studio/default.nix"
        ).is_file():
            return candidate
    raise SystemExit("Run `nix run .#fetch-deveco` from the nur-packages repository.")


def run_hdx(hdx: str, args: list[str], timeout: int) -> tuple[int, bytes]:
    master, slave = pty.openpty()
    proc = subprocess.Popen(
        [hdx, *args],
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
            if any(prompt in captured for prompt in PROMPT):
                proc.kill()
                os.close(master)
                raise SystemExit(LOGIN)
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


def urls_from(captured: bytes) -> list[str]:
    found: list[str] = []
    for match in URL_RE.findall(captured):
        url = match.decode("ascii", "ignore").rstrip(").,]}>\"'")
        if url not in found:
            found.append(url)
    return found


def download(url: str, dest: Path) -> None:
    temporary = dest.with_suffix(dest.suffix + ".partial")
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "nur-packages-deveco"},
    )
    read = 0
    next_report = 256 * 1024 * 1024
    try:
        with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as output:
            while True:
                block = response.read(1024 * 1024)
                if not block:
                    break
                output.write(block)
                read += len(block)
                if read >= next_report:
                    print(f"downloaded {read // (1024 * 1024)} MiB", file=sys.stderr)
                    next_report += 256 * 1024 * 1024
    except (urllib.error.URLError, TimeoutError, OSError):
        temporary.unlink(missing_ok=True)
        raise SystemExit("download failed") from None
    if read == 0:
        temporary.unlink(missing_ok=True)
        raise SystemExit("download failed")
    os.replace(temporary, dest)
    print(f"saved {dest.name} ({read // (1024 * 1024)} MiB)", file=sys.stderr)


def flat_hash(path: Path) -> str:
    sri = subprocess.check_output(
        ["nix", "hash", "file", "--sri", "--type", "sha256", str(path)],
        text=True,
    ).strip()
    if not HASH_RE.fullmatch(sri):
        raise SystemExit("nix hash did not return a flat sha256 SRI")
    return sri


def add_flat(path: Path) -> str:
    sri = flat_hash(path)
    result = subprocess.run(
        [
            "nix",
            "store",
            "add",
            "--mode",
            "flat",
            "--hash-algo",
            "sha256",
            "--name",
            path.name,
            str(path),
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0 or not result.stdout.strip().endswith("-" + path.name):
        raise SystemExit(f"could not add {path.name} to the Nix store")
    return sri


def render_sources(mac_name: str, mac_hash: str, cli_name: str, cli_hash: str) -> str:
    for name in (mac_name, cli_name):
        if not NAME_RE.fullmatch(name) or "://" in name:
            raise SystemExit("archive name is not safe to record")
    for digest in (mac_hash, cli_hash):
        if not HASH_RE.fullmatch(digest):
            raise SystemExit("archive hash is not safe to record")
    return (
        "{\n"
        "  mac = {\n"
        f'    name = "{mac_name}";\n'
        f'    hash = "{mac_hash}";\n'
        "  };\n"
        "  cli = {\n"
        f'    name = "{cli_name}";\n'
        f'    hash = "{cli_hash}";\n'
        "  };\n"
        "}\n"
    )


def fetch_tool(hdx: str, tool: str, directory: Path) -> tuple[str, str]:
    code, captured = run_hdx(hdx, ["-v", "dget", tool], timeout=180)
    urls = urls_from(captured)
    names = [filename_of(url) or "(unnamed)" for url in urls]
    print(
        f"hdx dget {tool} exit {code}; archive names: {', '.join(names) or '(none)'}",
        file=sys.stderr,
    )
    chosen = choose(tool, urls)
    if chosen is None:
        raise SystemExit(
            "hdx did not return the archive this package builds. "
            "deveco-studio needs a devecostudio-mac zip and "
            "command-line-tools-for-hmos needs commandline-tools-linux-x64."
        )
    name = filename_of(chosen)
    if not NAME_RE.fullmatch(name):
        raise SystemExit("archive name is not safe to record")
    dest = directory / name
    download(chosen, dest)
    return name, flat_sri(dest)


def flat_sri(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    sri = "sha256-" + base64.b64encode(digest.digest()).decode()
    if not HASH_RE.fullmatch(sri):
        raise SystemExit("archive hash is not safe to record")
    return sri


def write_output(output_dir: Path, mac: tuple[str, str], cli: tuple[str, str], directory: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(directory / mac[0], output_dir / "mac.zip")
    shutil.copyfile(directory / cli[0], output_dir / "cli.zip")
    mac_hash = flat_sri(output_dir / "mac.zip")
    cli_hash = flat_sri(output_dir / "cli.zip")
    text = f"mac.zip {mac_hash}\ncli.zip {cli_hash}\n"
    if "://" in text:
        raise SystemExit("refusing to record a URL")
    (output_dir / ".hashes").write_text(text)
    os.chmod(output_dir / ".hashes", 0o644)


def write_sources(root: Path, text: str) -> None:
    target = root / "pkgs/deveco-studio/sources.local.nix"
    temporary = target.with_name(target.name + ".tmp")
    temporary.write_text(text)
    os.chmod(temporary, 0o644)
    os.replace(temporary, target)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir")
    args = parser.parse_args()
    require_credentials()
    hdx = find_hdx()
    root = None if args.output_dir else repo_root()
    code, _captured = run_hdx(hdx, ["auth", "refresh"], timeout=180)
    if code != 0:
        raise SystemExit(LOGIN)
    print("hdx auth refresh finished", file=sys.stderr)

    with tempfile.TemporaryDirectory(prefix="deveco-fetch-") as raw:
        directory = Path(raw)
        os.chmod(directory, 0o700)
        mac = fetch_tool(hdx, "deveco-studio", directory)
        cli = fetch_tool(hdx, "command-line-tools-for-hmos", directory)
        if args.output_dir:
            write_output(Path(args.output_dir), mac, cli, directory)
        else:
            text = render_sources(
                mac[0], add_flat(directory / mac[0]), cli[0], add_flat(directory / cli[0])
            )
            if root is None or "://" in text:
                raise SystemExit("refusing to record a URL")
            write_sources(root, text)
    print(f"recorded hashes for {mac[0]} and {cli[0]}", file=sys.stderr)


if __name__ == "__main__":
    main()
