{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  unzip,
  python3,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  nss,
  gtk3,
  libgbm,
  libxshmfence,
  libGL,
  cups,
  dbus,
  udev,
  pango,
  glib,
  coreutils,
  xdg-utils,
  gsettings-desktop-schemas,
  runCommand,
  desktop-file-utils,
  xorg-server,
  xwininfo,
  sources ? import ./sources.nix,
  typoraSrc ? fetchurl (
    sources.typora.${stdenv.hostPlatform.system}
      or (throw "typora: unsupported system ${stdenv.hostPlatform.system}")
  ),
  pluginSrc ? fetchurl sources.plugin,
  extraFlags ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "typora";
  version = "${sources.typoraVersion}-plugin-${sources.pluginVersion}";
  src = typoraSrc;

  nativeBuildInputs = [
    dpkg
    unzip
    python3
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    alsa-lib
    nss
    gtk3
    libgbm
    libxshmfence
  ];
  runtimeDependencies = map lib.getLib [
    cups
    dbus
    pango
    # Electron loads libudev dynamically, so autoPatchelf cannot infer it.
    udev
  ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --no-same-owner --no-same-permissions -xf -
    mkdir plugin-source
    unzip -q ${pluginSrc} -d plugin-source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin" "$out/share/applications"
    cp -a usr/share/typora "$out/lib/typora"
    chmod -R u+w "$out/lib/typora"
    app="$out/lib/typora"
    test -x "$app/Typora"
    python3 ${./prepare.py} "$app" plugin-source/plugin

    if [ -d usr/share/icons ]; then cp -a usr/share/icons "$out/share/"; fi
    install -Dm644 usr/share/doc/typora/copyright \
      "$out/share/licenses/typora/typora-copyright"

    cat > "$out/share/applications/typora.desktop" <<DESKTOP
    [Desktop Entry]
    Name=Typora
    Comment=Markdown editor
    Exec=$out/bin/typora %U
    TryExec=$out/bin/typora
    Icon=typora
    Type=Application
    Terminal=false
    Categories=Office;TextEditor;
    MimeType=text/markdown;text/x-markdown;
    StartupWMClass=Typora
    DESKTOP

    substitute ${./launcher.sh} "$out/bin/typora" \
      --subst-var-by shell ${stdenv.shell} \
      --subst-var-by program "$app/Typora" \
      --subst-var-by extraFlags ${lib.escapeShellArg (lib.escapeShellArgs extraFlags)}
    chmod +x "$out/bin/typora"
    wrapProgram "$out/bin/typora" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL ]} \
      --prefix XDG_DATA_DIRS : ${
        lib.makeSearchPath "share/gsettings-schemas/${gsettings-desktop-schemas.name}" [
          gsettings-desktop-schemas
        ]
      } \
      --prefix PATH : ${
        lib.makeBinPath [
          glib
          coreutils
          xdg-utils
        ]
      }
    runHook postInstall
  '';

  passthru = {
    tests = import ./tests.nix {
      inherit
        runCommand
        python3
        desktop-file-utils
        xorg-server
        xwininfo
        ;
      package = finalAttrs.finalPackage;
    };
    inherit sources;
    inherit (sources) typoraVersion pluginVersion;
  };

  meta = {
    description = "Typora free beta with obgnail's Typora Plugin";
    homepage = "https://github.com/obgnail/typora_plugin";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "typora";
  };
})
