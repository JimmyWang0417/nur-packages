{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  cairo,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  libayatana-appindicator,
  libsoup_3,
  openssl,
  pango,
  webkitgtk_4_1,
  xz,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cc-switch";
  version = "4.0.40";

  src = fetchurl {
    url = "https://github.com/farion1231/cc-switch/releases/download/v${finalAttrs.version}/CC-Switch-v${finalAttrs.version}-Linux-x86_64.deb";
    hash = "sha256-5epZXUKi9lq0dcAO9w3gpCZ9iljf1sm6j/UTx2NTpsk=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapGAppsHook3
  ];

  buildInputs = [
    cairo
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    libayatana-appindicator
    libsoup_3
    openssl
    pango
    stdenv.cc.cc.lib
    webkitgtk_4_1
    xz
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/cc-switch" "$out/share"
    install -Dm755 usr/bin/cc-switch "$out/lib/cc-switch/cc-switch"
    cp -a usr/share/applications "$out/share/applications"
    cp -a usr/share/icons "$out/share/icons"

    runHook postInstall
  '';

  # libappindicator-sys dlopens libayatana-appindicator3.so.1. autoPatchelf
  # cannot see that name, so the wrapper puts the library on LD_LIBRARY_PATH.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${
        lib.escapeShellArg (lib.makeLibraryPath [ libayatana-appindicator ])
      }
    )
  '';

  postFixup = ''
    wrapGApp "$out/lib/cc-switch/cc-switch"
    mkdir -p "$out/bin"
    ln -s "$out/lib/cc-switch/cc-switch" "$out/bin/cc-switch"
  '';

  meta = {
    description = "All-in-One Assistant for Claude Code, Codex & Gemini CLI";
    homepage = "https://github.com/farion1231/cc-switch";
    license = lib.licenses.mit;
    mainProgram = "cc-switch";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
