{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "whitesur-kde";
  version = "0-unstable-2026-08-07";

  # Live kwinrc theme is __aurorae__svg__WhiteSur: the light round decoration
  # with no scale suffix. Button SVGs match aurorae/common/assets (not assets-dark).
  # The wallpaper directory name is wallpaper/WhiteSur, light plus dark 3840x2160.
  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-kde";
    rev = "cf4df59ce91004f7ea39358b1b8ff917d5c329f7";
    hash = "sha256-Fi2zffRhTPd07jTe3YgGkgFK4wjPv+Vq0iljWxLQDBU=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    theme="$out/share/aurorae/themes/WhiteSur"
    mkdir -p "$theme" "$out/share/wallpapers"
    cp aurorae/main/WhiteSur/decoration.svg "$theme/decoration.svg"
    cp aurorae/common/assets/*.svg "$theme/"
    cp aurorae/metadata.desktop aurorae/metadata.json "$theme/"
    cp aurorae/main/WhiteSurrc "$theme/WhiteSurrc"
    cp -a wallpaper/WhiteSur "$out/share/wallpapers/WhiteSur"
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
