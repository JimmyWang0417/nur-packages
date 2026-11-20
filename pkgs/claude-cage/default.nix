{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  cacert,
  cairo,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  json-glib,
  pango,
  webkitgtk_4_1,
  git,
  iproute2,
  libnotify,
  openssh,
  qemu,
  zenity,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-cage";
  version = "0.1.8";

  src = fetchurl {
    url = "https://github.com/Lee-xeo/Claude-Cage/releases/download/v${finalAttrs.version}/Cage-${finalAttrs.version}-linux-amd64.deb";
    hash = "sha256-fraLAN2Uwmw7KzQIwz0eBH6voIoQu2yoyFEYiWNF4Bg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    cairo
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    json-glib
    pango
    stdenv.cc.cc.lib
    webkitgtk_4_1
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  # The archive root is mode 0700. Extract into a subdirectory and reopen it
  # so the installed tree is readable.
  unpackPhase = ''
    runHook preUnpack
    mkdir extracted
    dpkg-deb -x "$src" extracted
    chmod -R u+rwX,go+rX extracted
    cd extracted
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib" "$out/share"
    cp -a usr/lib/claude-cage "$out/lib/claude-cage"
    cp -a usr/share/applications "$out/share/applications"
    cp -a usr/share/icons "$out/share/icons"

    substituteInPlace "$out/share/applications/io.github.lee_xeo.Cage.desktop" \
      --replace-fail "Exec=/usr/bin/cage-desktop" "Exec=cage-desktop"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.escapeShellArg (lib.makeBinPath [
          git
          iproute2
          libnotify
          openssh
          qemu
          zenity
        ])
      }
      --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
    )
  '';

  # cage-desktop finds the backend with /proc/self/exe, so the ELF stays
  # beside cage and mihomo. The bin entries are wrappers.
  postFixup = ''
    wrapGApp "$out/lib/claude-cage/cage-desktop"
    mkdir -p "$out/bin"
    ln -s "$out/lib/claude-cage/cage-desktop" "$out/bin/cage-desktop"
    makeWrapper "$out/lib/claude-cage/cage" "$out/bin/claude-cage" \
      --prefix PATH : ${
        lib.escapeShellArg (lib.makeBinPath [
          git
          iproute2
          libnotify
          openssh
          qemu
          zenity
        ])
      } \
      --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/cage-desktop" --version | grep -F "Cage ${finalAttrs.version}"
    "$out/bin/cage-desktop" --self-test
    runHook postInstallCheck
  '';

  meta = {
    description = "Isolated coding workspace with a persistent Linux VM";
    homepage = "https://github.com/Lee-xeo/Claude-Cage";
    # The desktop and backend are MIT. The deb also ships the GPL-3 Mihomo core.
    license = with lib.licenses; [
      mit
      gpl3Plus
    ];
    mainProgram = "cage-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
