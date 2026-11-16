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
    # xsi-addon-symbolic.svg points at application-x-addon-symbolic.svg, which
    # is not in symbolic/apps. That file is shipped in symbolic/mimetypes, and
    # the same icon is also addon-symbolic.svg. Retarget when one of those
    # exists; drop the link only when the target is absent upstream.
    addon="$dest/symbolic/apps/xsi-addon-symbolic.svg"
    if [[ -L $addon && ! -e $addon ]]; then
      if [[ -e $dest/symbolic/mimetypes/application-x-addon-symbolic.svg ]]; then
        ln -sfn ../mimetypes/application-x-addon-symbolic.svg "$addon"
      elif [[ -e $dest/symbolic/apps/addon-symbolic.svg ]]; then
        ln -sfn addon-symbolic.svg "$addon"
      else
        rm -f "$addon"
      fi
    fi
    runHook postInstall
  '';

  meta = {
    description = "Tela icon theme, standard color";
    homepage = "https://github.com/vinceliuice/Tela-icon-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
