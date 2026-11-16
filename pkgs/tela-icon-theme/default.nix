{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "tela-icon-theme";
  version = "0-unstable-2026-08-10";

  # Live ~/.local/share/icons/Tela is the standard color, directory name Tela.
  # index.theme matches src/index.theme with %NAME% replaced by Tela, including
  # FollowsColorScheme=true. Not Tela-dark, Tela-light, or a recolored variant.
  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Tela-icon-theme";
    rev = "a1fffc5bfab716bd022dd228ee96fe3965cdb33d";
    hash = "sha256-e4Ysu9YE2jAib9+q9eYL0E3w1BBXbu/QYNTmSjk0CRY=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    dest="$out/share/icons/Tela"
    mkdir -p "$dest"
    cp -a src/. "$dest/"
    cp -a links/. "$dest/"
    substituteInPlace "$dest/index.theme" --replace-fail '%NAME%' 'Tela'
    ln -s 16 "$dest/16@2x"
    ln -s 22 "$dest/22@2x"
    ln -s 24 "$dest/24@2x"
    ln -s 32 "$dest/32@2x"
    ln -s scalable "$dest/scalable@2x"
    find "$dest" -xtype l -delete
    runHook postInstall
  '';

  meta = {
    description = "Tela icon theme, standard color";
    homepage = "https://github.com/vinceliuice/Tela-icon-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
