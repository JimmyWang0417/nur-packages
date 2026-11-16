{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  file,
  python3,
}:
stdenvNoCC.mkDerivation {
  pname = "endeavouros-wallpapers";
  version = "0-unstable-2026-07-21";

  # Default branch of the official EndeavourOS branding repository.
  # endeavouros-branding installs these PNGs, and eos-settings-plasma
  # points the Plasma wallpaper EndeavourOS at endeavouros-wallpaper.png.
  src = fetchFromGitHub {
    owner = "endeavouros-team";
    repo = "Branding";
    rev = "b0b0b3453216d2e1daacd0dd20ecdbe697ae098a";
    hash = "sha256-tgCQnW6NxPoRUA8oTtJLhRbuU/h0TG2CeO0E9lyU3ms=";
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
    names = {
        "endeavouros-wallpaper.png": "EndeavourOS",
        "endeavouros-wallpaper-light.png": "EndeavourOS Light",
    }
    installed = []
    for src in sorted(Path("backgrounds").iterdir()):
        if src.name not in names and not src.name.startswith("endeavouros-wallpaper"):
            continue
        if not src.is_file() or src.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
            continue
        name = names.get(src.name, "EndeavourOS " + src.stem)
        info = subprocess.check_output(["file", "-b", "--", str(src)], text=True)
        matches = re.findall(r"(\d+)\s*x\s*(\d+)", info)
        if not matches:
            raise SystemExit(f"no dimensions for {src}: {info}")
        width, height = matches[-1]
        package = out / "share/wallpapers" / name
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
    if "EndeavourOS" not in installed or "EndeavourOS Light" not in installed:
        raise SystemExit(f"missing official wallpapers, got {installed}")
    PY
    runHook postInstall
  '';

  meta = {
    description = "EndeavourOS default and light wallpapers";
    homepage = "https://github.com/endeavouros-team/Branding";
    license = lib.licenses.cc-by-sa-40;
    platforms = lib.platforms.all;
  };
}
