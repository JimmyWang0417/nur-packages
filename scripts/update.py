#!/usr/bin/env python3
"""Bump packages listed in updates.nix.

Inputs:
  updates.nix, read with `nix eval --file ./updates.nix --json`.
  Each item has attribute, file, owner, repo, kind, asset.

  kind = "github-asset":
    latest GitHub release tag, with one leading "v" removed, is the new version.
    The file is downloaded from
    https://github.com/<owner>/<repo>/releases/download/v<version>/<asset>
    where "{version}" inside asset is replaced. version and the first
    hash = "sha256-..." line in the nix file are rewritten.
    `nix store prefetch-file --hash-type sha256 --json` supplies the hash.

  kind = "github-source":
    same version rule. The fetchFromGitHub hash is taken from
    `nix flake prefetch github:<owner>/<repo>/v<version>`.
    Cargo.lock beside the nix file is regenerated with cargo generate-lockfile
    on that tag. This is how crm opts in. There is no separate cargoHash line.

A package that is not listed is never modified.

Outputs:
  rewritten nix files and, for github-source, a new Cargo.lock.
  The workflow then commits those files on a new branch update/weekly-<UTC stamp>
  and opens a pull request. It does not force-push.
"""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(cmd, **kwargs):
    return subprocess.check_output(cmd, text=True, **kwargs)


def load_updates():
    raw = run(
        [
            "nix",
            "--extra-experimental-features",
            "nix-command flakes",
            "eval",
            "--file",
            str(ROOT / "updates.nix"),
            "--json",
        ]
    )
    return json.loads(raw)


def latest_version(owner: str, repo: str) -> str:
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "nur-packages-update",
        },
    )
    with urllib.request.urlopen(req) as resp:
        tag = json.load(resp)["tag_name"]
    return tag[1:] if tag.startswith("v") else tag


def current_version(text: str) -> str:
    match = re.search(r'version = "([^"]+)";', text)
    if not match:
        raise SystemExit("version assignment not found")
    return match.group(1)


def replace_once(text: str, pattern: str, repl: str, label: str) -> str:
    new, count = re.subn(pattern, repl, text, count=1)
    if count != 1:
        raise SystemExit(f"expected one {label}, found {count}")
    return new


def prefetch_url(url: str) -> str:
    raw = run(
        [
            "nix",
            "--extra-experimental-features",
            "nix-command flakes",
            "store",
            "prefetch-file",
            "--hash-type",
            "sha256",
            "--json",
            url,
        ]
    )
    return json.loads(raw)["hash"]


def prefetch_github(owner: str, repo: str, version: str) -> str:
    raw = run(
        [
            "nix",
            "--extra-experimental-features",
            "nix-command flakes",
            "flake",
            "prefetch",
            "--json",
            f"github:{owner}/{repo}/v{version}",
        ]
    )
    return json.loads(raw)["hash"]


def regenerate_cargo_lock(owner: str, repo: str, version: str, dest: Path) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / "src.tar.gz"
        url = f"https://github.com/{owner}/{repo}/archive/refs/tags/v{version}.tar.gz"
        subprocess.check_call(["curl", "-fsSL", "-o", str(archive), url])
        subprocess.check_call(["tar", "-xzf", str(archive), "-C", tmp])
        src = next(Path(tmp).glob(f"{repo}-*"))
        subprocess.check_call(
            [
                "nix",
                "--extra-experimental-features",
                "nix-command flakes",
                "shell",
                "github:NixOS/nixpkgs/nixos-26.05#cargo",
                "github:NixOS/nixpkgs/nixos-26.05#rustc",
                "--command",
                "cargo",
                "generate-lockfile",
            ],
            cwd=src,
        )
        dest.write_bytes((src / "Cargo.lock").read_bytes())


def update_asset(item: dict) -> bool:
    path = ROOT / item["file"]
    text = path.read_text()
    current = current_version(text)
    version = latest_version(item["owner"], item["repo"])
    print(f"{item['attribute']}: {current} -> {version}")
    if version == current:
        return False
    asset = item["asset"].replace("{version}", version)
    url = (
        f"https://github.com/{item['owner']}/{item['repo']}"
        f"/releases/download/v{version}/{asset}"
    )
    sri = prefetch_url(url)
    text = replace_once(text, r'version = "[^"]+";', f'version = "{version}";', "version")
    text = replace_once(text, r'hash = "sha256-[^"]+";', f'hash = "{sri}";', "hash")
    path.write_text(text)
    return True


def update_source(item: dict) -> bool:
    path = ROOT / item["file"]
    text = path.read_text()
    current = current_version(text)
    version = latest_version(item["owner"], item["repo"])
    print(f"{item['attribute']}: {current} -> {version}")
    if version == current:
        return False
    sri = prefetch_github(item["owner"], item["repo"], version)
    text = replace_once(text, r'version = "[^"]+";', f'version = "{version}";', "version")
    text = replace_once(text, r'hash = "sha256-[^"]+";', f'hash = "{sri}";', "hash")
    path.write_text(text)
    regenerate_cargo_lock(item["owner"], item["repo"], version, path.parent / "Cargo.lock")
    return True


def main() -> None:
    changed = False
    for item in load_updates():
        kind = item["kind"]
        if kind == "github-asset":
            changed = update_asset(item) or changed
        elif kind == "github-source":
            changed = update_source(item) or changed
        else:
            raise SystemExit(f"unknown kind {kind} for {item['attribute']}")
    if not changed:
        print("no version changes")


if __name__ == "__main__":
    main()
