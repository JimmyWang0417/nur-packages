{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "grub-theme-dedsec";
  version = "0-unstable-2025-10-24";

  # Live /boot/grub/themes/dedsec is this repo's 1440p theme: theme.txt
  # matches base/1440p, background.png is fuckery-1440p.png (2813545 bytes),
  # and the icons match assets/icons-1440p/color.
  src = fetchFromGitHub {
    owner = "VandalByte";
    repo = "dedsec-grub2-theme";
    rev = "bbfe078386545688727f44897a7fede8af2c6dda";
    hash = "sha256-Q84+WZLO6C8jiphuwBxeECy5OM2+c3ZJCZ+8v0546EM=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/icons"
    cp assets/backgrounds/fuckery-1440p.png "$out/background.png"
    cp -r assets/icons-1440p/color/. "$out/icons/"
    cp -r assets/fonts/1440p/. "$out/"
    cp -r base/1440p/. "$out/"
    runHook postInstall
  '';

  meta = {
    description = "DedSec GRUB theme (fuckery, 1440p, color icons)";
    homepage = "https://github.com/VandalByte/dedsec-grub2-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
