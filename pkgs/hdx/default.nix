# The public chawyehsu/hdx repository publishes no Linux source and no Linux
# binary. v0.1.2, the current release, is a Windows console program. This
# package runs that binary through Wine so the DevEco fetch has an `hdx` on
# PATH even when the machine has none installed. The wrapper does not log in
# and does not download DevEco.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  wine64,
  writeShellScript,
}:
let
  runner = writeShellScript "hdx-run" ''
    set -eu
    if [ -z "''${XDG_CONFIG_HOME:-}" ] && [ -n "''${HOME:-}" ]; then
      export XDG_CONFIG_HOME="$HOME/.config"
    fi
    export WINEDEBUG="''${WINEDEBUG:--all}"
    case "''${WINEDLLOVERRIDES:-}" in
      *mscoree*) ;;
      "") export WINEDLLOVERRIDES="mscoree,mshtml=" ;;
      *) export WINEDLLOVERRIDES="mscoree,mshtml=;''${WINEDLLOVERRIDES}" ;;
    esac
    if [ -n "''${HOME:-}" ]; then
      export WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/hdx/wine}"
      mkdir -p "$WINEPREFIX"
    fi
    exec ${lib.getExe wine64} "@exe@" "$@"
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hdx";
  version = "0.1.2";

  src = fetchurl {
    url = "https://github.com/chawyehsu/hdx/releases/download/v${finalAttrs.version}/hdx-x86-64-pc-windows-msvc.zip";
    hash = "sha256-EWhshiBxt1fCL6nvFGHn8nUZbwcMVo/hewjR11qoPW4=";
  };

  nativeBuildInputs = [ unzip ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    unzip -q "$src" -d "$TMPDIR/hdx-src"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/libexec"
    install -m755 "$TMPDIR/hdx-src/hdx.exe" "$out/libexec/hdx.exe"
    substitute ${runner} "$out/bin/hdx" --replace-fail @exe@ "$out/libexec/hdx.exe"
    chmod 755 "$out/bin/hdx"
    runHook postInstall
  '';

  meta = {
    description = "Huawei developer download CLI, packaged for Linux";
    homepage = "https://github.com/chawyehsu/hdx";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "hdx";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
