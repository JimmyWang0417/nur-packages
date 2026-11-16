{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "breath-wallpapers";
  version = "0-unstable-2024-06-07";

  # GitHub mirror of https://code.manjaro.org/artwork/breath. The daily
  # github-rev updater follows this repository's default branch. HEAD already
  # contains Bamboo, Bamboo at Night, North, and Foreland.
  src = fetchFromGitHub {
    owner = "manjaro-contrib";
    repo = "artwork-themes-breath";
    rev = "1b708941f52be6f36ed61635659ad1d26c5719d7";
    hash = "sha256-XpKhEMqD9j02zgkI9NUqmZnEEracZzuOgNA/ZbTi1Nw=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/wallpapers"
    find wallpapers -mindepth 1 -maxdepth 1 -type d -exec cp -a {} "$out/share/wallpapers/" \;
    for name in Bamboo "Bamboo at Night" North Foreland; do
      test -d "$out/share/wallpapers/$name"
    done
    runHook postInstall
  '';

  meta = {
    description = "Manjaro Breath wallpapers (Bamboo, Bamboo at Night, North, Foreland)";
    homepage = "https://code.manjaro.org/artwork/breath";
    license = lib.licenses.cc-by-sa-40;
    platforms = lib.platforms.all;
  };
}
