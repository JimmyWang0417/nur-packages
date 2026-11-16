{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  # 壁纸和边框是两次不同提交，不跟默认分支一起更新.
  # The paths below follow whichever layout that revision has.
  wallpaper = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-kde";
    # Live light and dark 3840x2160 PNGs. Committer date 2024-10-12.
    rev = "eb7b054b1c7c3429965e3b531de2db38e2c83aec";
    hash = "sha256-KBhvsfXLICBwCOL03FHc8Z7gT6hKRL+Dzi1w3ufJFtI=";
  };
  decoration = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-kde";
    # Live Aurorae theme, including decoration.svg and WhiteSurrc.
    # Committer date 2022-06-25. The theme directory is aurorae/WhiteSur/.
    rev = "36dfbd08b1cdd408c61c986b900b3b45fc98776d";
    hash = "sha256-AzHuJrOwlnpjXE00PqcwHbSVXsZhtFXpVJbpq26hSMU=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "whitesur-kde";
  version = "0-unstable-2024-10-12";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    theme="$out/share/aurorae/themes/WhiteSur"
    mkdir -p "$theme" "$out/share/wallpapers"
    if [[ -d "${decoration}/aurorae/WhiteSur" ]]; then
      cp -a "${decoration}/aurorae/WhiteSur/." "$theme/"
    else
      cp "${decoration}/aurorae/main/WhiteSur/decoration.svg" "$theme/decoration.svg"
      cp "${decoration}/aurorae/common/assets/"*.svg "$theme/"
      cp "${decoration}/aurorae/metadata.desktop" "${decoration}/aurorae/metadata.json" "$theme/"
      cp "${decoration}/aurorae/main/WhiteSurrc" "$theme/WhiteSurrc"
    fi
    cp -a "${wallpaper}/wallpaper/WhiteSur" "$out/share/wallpapers/WhiteSur"
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
