{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  file,
  python3,
}:
stdenvNoCC.mkDerivation {
  pname = "endeavouros-community-wallpapers";
  version = "0-unstable-2026-11-16";

  # Classic release wallpapers and the community set linked from
  # endeavouros-team/Branding. One rev, so the daily github-rev updater
  # can follow the default branch.
  src = fetchFromGitHub {
    owner = "EndeavourOS-Community-Editions";
    repo = "Community-wallpapers";
    rev = "6b68066f583196aa71485940cb10412d58dbc867";
    hash = "sha256-UYAklciEVb73/bc3Fcj4RZVHMdCmjZwAGp/GDDnwnRM=";
  };

  nativeBuildInputs = [
    file
    python3
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    out="$out" python3 - <<'PY'
    import json, os, re, subprocess
    from pathlib import Path

    out = Path(os.environ["out"])
    sets = (
        ("eos_wallpapers_classic", "EndeavourOS Classic"),
        ("eos_wallpapers_community", "EndeavourOS Community"),
    )
    extensions = {".png", ".jpg", ".jpeg", ".webp"}
    installed = []
    for folder, prefix in sets:
        root = Path(folder)
        if not root.is_dir():
            raise SystemExit(f"missing {folder}")
        for src in sorted(root.iterdir()):
            if not src.is_file() or src.suffix.lower() not in extensions:
                continue
            name = f"{prefix} {src.stem.strip()}"
            package = out / "share/wallpapers" / name
            if package.exists():
                name = f"{prefix} {src.name}"
                package = out / "share/wallpapers" / name
            if package.exists():
                raise SystemExit(f"duplicate wallpaper {name}")
            info = subprocess.check_output(["file", "-b", "--", str(src)], text=True)
            matches = re.findall(r"(\d+)\s*x\s*(\d+)", info)
            if not matches:
                raise SystemExit(f"no dimensions for {src}: {info}")
            width, height = matches[-1]
            images = package / "contents/images"
            images.mkdir(parents=True)
            (images / f"{width}x{height}{src.suffix.lower()}").write_bytes(src.read_bytes())
            (package / "metadata.json").write_text(json.dumps({
                "KPlugin": {
                    "Id": name,
                    "License": "CC-BY-SA-4.0",
                    "Name": name,
                }
            }, indent=2) + "\n")
            installed.append(name)
    if len(installed) < 2:
        raise SystemExit(f"expected wallpaper sets, installed {len(installed)}")
    PY
    runHook postInstall
  '';

  meta = {
    description = "EndeavourOS classic and community wallpapers";
    homepage = "https://github.com/EndeavourOS-Community-Editions/Community-wallpapers";
    license = lib.licenses.cc-by-sa-40;
    platforms = lib.platforms.all;
  };
}
