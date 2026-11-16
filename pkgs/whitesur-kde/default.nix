{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "whitesur-kde";
  version = "0-unstable-2026-08-07";

  # Wallpaper and Aurorae decoration come from one default-branch checkout.
  # The daily github-rev updater rewrites this single rev and hash together.
  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-kde";
    rev = "cf4df59ce91004f7ea39358b1b8ff917d5c329f7";
    hash = "sha256-Fi2zffRhTPd07jTe3YgGkgFK4wjPv+Vq0iljWxLQDBU=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    theme="$out/share/aurorae/themes/WhiteSur"
    mkdir -p "$theme" "$out/share/wallpapers"
    if [[ -d "''${src}/aurorae/WhiteSur" ]]; then
      cp -a "''${src}/aurorae/WhiteSur/." "$theme/"
    else
      cp "''${src}/aurorae/main/WhiteSur/decoration.svg" "$theme/decoration.svg"
      cp "''${src}/aurorae/common/assets/"*.svg "$theme/"
      cp "''${src}/aurorae/metadata.desktop" "''${src}/aurorae/metadata.json" "$theme/"
      cp "''${src}/aurorae/main/WhiteSurrc" "$theme/WhiteSurrc"
    fi
    cp -a "''${src}/wallpaper/WhiteSur" "$out/share/wallpapers/WhiteSur"
    runHook postInstall
  '';

  meta = {
    description = "WhiteSur KDE Aurorae decoration and wallpaper";
    homepage = "https://github.com/vinceliuice/WhiteSur-kde";
    license = with lib.licenses; [
      gpl3Only
      cc-by-sa-40
    ];
    platforms = lib.platforms.all;
  };
}
