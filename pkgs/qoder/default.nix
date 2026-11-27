{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libglvnd,
  libnotify,
  libsecret,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  util-linux,
  vulkan-loader,
  xdg-utils,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxscrnsaver,
  libxtst,
  libxcb,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "qoder";
  version = "0.5.21";

  src = fetchurl {
    url = "https://download.qoder.com/qoder-app/releases/${finalAttrs.version}/Qoder-linux-amd64.deb";
    hash = "sha256-/3Y7g8tRGEfiw4Ugo45w3NixfWuV04rqPy2b6u8szuw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libglvnd
    libnotify
    libsecret
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    util-linux
    vulkan-loader
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxscrnsaver
    libxtst
    libxcb
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  # Upstream ships a musl build of sharp beside the glibc one. NixOS uses the
  # glibc copy, so the musl interpreter is not a runtime dependency.
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
  ];

  # ar + tar, not dpkg-deb: the deb marks chrome-sandbox executable for every
  # user, and dpkg-deb preserves that mode in a way the Nix sandbox rejects.
  unpackPhase = ''
    runHook preUnpack
    ar x "$src"
    tar -xf data.tar.* --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt" "$out/bin" "$out/share"
    cp -a opt/Qoder "$out/opt/Qoder"
    cp -a usr/share/icons "$out/share/icons"
    install -Dm644 usr/share/applications/qoder.desktop \
      "$out/share/applications/qoder.desktop"
    substituteInPlace "$out/share/applications/qoder.desktop" \
      --replace-fail "/opt/Qoder/qoder" "qoder"

    chmod 755 "$out/opt/Qoder/qoder" \
      "$out/opt/Qoder/chrome-sandbox" \
      "$out/opt/Qoder/chrome_crashpad_handler"

    makeWrapper "$out/opt/Qoder/qoder" "$out/bin/qoder" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix LD_LIBRARY_PATH : "$out/opt/Qoder:${
        lib.makeLibraryPath [
          libglvnd
          mesa
          vulkan-loader
          alsa-lib
        ]
      }"

    runHook postInstall
  '';

  meta = {
    description = "Qoder, the official international Linux desktop for the Qoder coding IDE";
    homepage = "https://qoder.com/";
    license = lib.licenses.unfree;
    mainProgram = "qoder";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
