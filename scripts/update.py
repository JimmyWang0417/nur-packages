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

  kind = "typora-plugin":
    update only pluginVersion and the plugin source block in sources.nix.
    Preserve the actual release tag (with or without v), require the matching
    release asset, and leave the historical Typora editor and architecture
    hashes pinned. CI validates the updated package before committing to main.

  kind = "github-rev":
    latest commit on the default branch. When that SHA differs from any
    `rev`, every rev and every sha256 hash in the file are rewritten to
    that commit. The hash comes from
    `nix flake prefetch github:<owner>/<repo>/<rev>`, which matches
    fetchFromGitHub. A version of the form 0-unstable-YYYY-MM-DD is set
    from the committer date. Hashes already in the file are left alone
    until that rewrite.

  kind = "github-version":
    latest GitHub release tag. One leading "v" is ignored, and a trailing
    "-<digits>" package release is removed. Only the first
    version = "..." assignment is rewritten. Nothing is downloaded and no
    hash line is changed.

  kind = "http-version":
    When versionPattern is set, GET versionUrl and take the first
    capture group. Otherwise HEAD versionUrl and read versionHeader
    (Qoder CN publishes x-oss-meta-version on the latest deb).
    version and the first hash = "sha256-..." line are rewritten from
    fileUrl, with "{version}" replaced. The nix expression keeps the
    version in the download URL, so that line is not edited separately.

  UPDATE_KINDS, if set, is a comma-separated subset of kinds to process.
  The daily cron sets it to github-rev,http-version,github-version. An empty
  value updates every entry.
  GitHub API calls send Authorization: Bearer $GITHUB_TOKEN when that
  variable is set. Actions otherwise shares the unauthenticated rate limit.

A package that is not listed is never modified.

Outputs:
  rewritten nix files and, for github-source, a new Cargo.lock.
  The workflow commits those files and pushes them to main only when the
  worktree changed. It does not open a pull request and does not force-push.
"""

from __future__ import annotations

import json
import os
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


def github_json(url: str) -> dict:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "nur-packages-update",
    }
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)


def latest_release(owner: str, repo: str) -> dict:
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    return github_json(url)


def latest_version(owner: str, repo: str) -> str:
    tag = latest_release(owner, repo)["tag_name"]
    return tag[1:] if tag.startswith("v") else tag


def current_version(text: str) -> str:
    match = re.search(r'version = "([^"]+)";', text)
    if not match:
        raise SystemExit("version assignment not found")
    return match.group(1)


def current_revs(text: str) -> list[str]:
    return re.findall(r'rev = "([0-9a-fA-F]+)";', text)


def latest_commit(owner: str, repo: str) -> tuple[str, str]:
    url = f"https://api.github.com/repos/{owner}/{repo}/commits/HEAD"
    data = github_json(url)
    day = data["commit"]["committer"]["date"][:10]
    return data["sha"], day


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


def prefetch_github_ref(owner: str, repo: str, ref: str) -> str:
    raw = run(
        [
            "nix",
            "--extra-experimental-features",
            "nix-command flakes",
            "flake",
            "prefetch",
            "--json",
            f"github:{owner}/{repo}/{ref}",
        ]
    )
    return json.loads(raw)["hash"]


def prefetch_github(owner: str, repo: str, version: str) -> str:
    return prefetch_github_ref(owner, repo, f"v{version}")


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


def update_rev(item: dict) -> bool:
    path = ROOT / item["file"]
    text = path.read_text()
    current = current_revs(text)
    if not current:
        raise SystemExit("rev assignment not found")
    rev, day = latest_commit(item["owner"], item["repo"])
    print(f"{item['attribute']}: {', '.join(current)} -> {rev}")
    if all(item_rev == rev for item_rev in current):
        return False
    sri = prefetch_github_ref(item["owner"], item["repo"], rev)
    text, rev_count = re.subn(r'rev = "[0-9a-fA-F]+";', f'rev = "{rev}";', text)
    text, hash_count = re.subn(r'hash = "sha256-[^"]+";', f'hash = "{sri}";', text)
    if rev_count < 1 or hash_count != rev_count:
        raise SystemExit(
            f"expected matching rev and hash assignments, found {rev_count} rev and {hash_count} hash"
        )
    version_pattern = r'version = "0-unstable-\d{4}-\d{2}-\d{2}";'
    if re.search(version_pattern, text):
        text = replace_once(
            text,
            version_pattern,
            f'version = "0-unstable-{day}";',
            "version",
        )
    path.write_text(text)
    return True


def version_from_body(body: str, pattern: str) -> str:
    match = re.search(pattern, body)
    if not match:
        raise SystemExit("versionPattern did not match the version document")
    value = match.group(1).strip()
    if not value:
        raise SystemExit("versionPattern matched an empty version")
    return value


def latest_http_version(item: dict) -> str:
    pattern = (item.get("versionPattern") or "").strip()
    if pattern:
        req = urllib.request.Request(
            item["versionUrl"],
            headers={"User-Agent": "nur-packages-update"},
        )
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode("utf-8", "replace")
        return version_from_body(body, pattern)
    req = urllib.request.Request(
        item["versionUrl"],
        method="HEAD",
        headers={"User-Agent": "nur-packages-update"},
    )
    with urllib.request.urlopen(req) as resp:
        value = resp.headers.get(item["versionHeader"])
    if not value or not str(value).strip():
        raise SystemExit(
            f"header {item['versionHeader']} missing from {item['versionUrl']}"
        )
    return str(value).strip()


def update_http_version(item: dict) -> bool:
    path = ROOT / item["file"]
    text = path.read_text()
    current = current_version(text)
    version = latest_http_version(item)
    print(f"{item['attribute']}: {current} -> {version}")
    if version == current:
        return False
    url = item["fileUrl"].replace("{version}", version)
    sri = prefetch_url(url)
    text = replace_once(text, r'version = "[^"]+";', f'version = "{version}";', "version")
    text = replace_once(text, r'hash = "sha256-[^"]+";', f'hash = "{sri}";', "hash")
    path.write_text(text)
    return True


def update_typora_plugin(item: dict) -> bool:
    """Update only the plugin release; the historical free editor stays pinned."""
    path = ROOT / item["file"]
    text = path.read_text()
    versions = re.findall(r'pluginVersion = "([^"]+)";', text)
    blocks = list(re.finditer(r'(?ms)^  plugin = \{\n.*?^  \};', text))
    if len(versions) != 1 or len(blocks) != 1:
        raise SystemExit("expected one pluginVersion and one plugin source block")

    release = latest_release(item["owner"], item["repo"])
    tag = release["tag_name"]
    if not re.fullmatch(r"v?\d+\.\d+\.\d+", tag):
        raise SystemExit(f"unexpected Typora plugin release tag: {tag}")
    version = tag.removeprefix("v")
    print(f"{item['attribute']} plugin: {versions[0]} -> {version}")
    if version == versions[0]:
        return False

    asset = item["asset"].replace("{version}", version)
    if not any(entry["name"] == asset for entry in release["assets"]):
        raise SystemExit(f"Typora plugin release {tag} has no {asset}")
    url = (f"https://github.com/{item['owner']}/{item['repo']}"
           f"/releases/download/{tag}/{asset}")
    sri = prefetch_url(url)
    if not re.fullmatch(r"sha256-[A-Za-z0-9+/]{43}=", sri):
        raise SystemExit("unexpected SHA-256 hash from prefetch-file")
    match = blocks[0]
    block = match.group()
    for pattern, value, label in [
        (r'url = "[^"]+";', f'url = "{url}";', "plugin URL"),
        (r'hash = "sha256-[^"]+";', f'hash = "{sri}";', "plugin hash"),
    ]:
        block, count = re.subn(pattern, lambda _: value, block)
        if count != 1:
            raise SystemExit(f"expected one {label}, found {count}")
    text = text[:match.start()] + block + text[match.end():]
    text = re.sub(r'pluginVersion = "[^"]+";',
                  f'pluginVersion = "{version}";', text)
    path.write_text(text)
    return True


RELEASE_VERSION = re.compile(r"v?(?P<version>\d+\.\d+\.\d+\.\d+)(?:-\d+)?\Z")


def release_version(owner: str, repo: str) -> str:
    tag = str(latest_release(owner, repo)["tag_name"]).strip()
    match = RELEASE_VERSION.fullmatch(tag)
    if not match or "://" in tag or "/" in tag:
        raise SystemExit(f"unexpected release tag: {tag}")
    return match.group("version")


def update_release_version(item: dict) -> bool:
    """Rewrite the version string from a public GitHub release tag."""
    path = ROOT / item["file"]
    text = path.read_text()
    current = current_version(text)
    version = release_version(item["owner"], item["repo"])
    print(f"{item['attribute']}: {current} -> {version}")
    if version == current:
        return False
    text = replace_once(text, r'version = "[^"]+";', f'version = "{version}";', "version")
    if "://" in version:
        raise SystemExit("refusing a version that looks like a URL")
    path.write_text(text)
    return True


def main() -> None:
    changed = False
    allowed = {
        part.strip()
        for part in os.environ.get("UPDATE_KINDS", "").split(",")
        if part.strip()
    }
    for item in load_updates():
        kind = item["kind"]
        if allowed and kind not in allowed:
            continue
        if kind == "github-asset":
            changed = update_asset(item) or changed
        elif kind == "github-source":
            changed = update_source(item) or changed
        elif kind == "typora-plugin":
            changed = update_typora_plugin(item) or changed
        elif kind == "github-rev":
            changed = update_rev(item) or changed
        elif kind == "http-version":
            changed = update_http_version(item) or changed
        elif kind == "github-version":
            changed = update_release_version(item) or changed
        else:
            raise SystemExit(f"unknown kind {kind} for {item['attribute']}")
    if not changed:
        print("no upstream changes")


if __name__ == "__main__":
    main()
