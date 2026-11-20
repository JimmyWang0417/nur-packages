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
  xorg,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "qoder";
  version = "0.5.16";

  src = fetchurl {
    url = "https://qoder-app.oss-cn-beijing.aliyuncs.com/qoder-app/releases/${finalAttrs.version}/Qoder-CN-linux-amd64.deb";
    hash = "sha256-V9aAfbHX0E+L3/g9yzZtruzupEJJWsa9STsRtSV2I8Y=";
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
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libxcb
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

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
    cp -a opt/Qoder-CN "$out/opt/Qoder-CN"
    cp -a usr/share/icons "$out/share/icons"
    install -Dm644 usr/share/applications/qoder-cn.desktop \
      "$out/share/applications/qoder-cn.desktop"
    substituteInPlace "$out/share/applications/qoder-cn.desktop" \
      --replace-fail "/opt/Qoder-CN/qoder-cn" "qoder-cn"

    chmod 755 "$out/opt/Qoder-CN/qoder-cn" \
      "$out/opt/Qoder-CN/chrome-sandbox" \
      "$out/opt/Qoder-CN/chrome_crashpad_handler"

    makeWrapper "$out/opt/Qoder-CN/qoder-cn" "$out/bin/qoder-cn" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix LD_LIBRARY_PATH : "$out/opt/Qoder-CN:${
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
    description = "Qoder CN, the official Linux desktop for the Qoder coding IDE";
    homepage = "https://qoder.com.cn";
    license = lib.licenses.unfree;
    mainProgram = "qoder-cn";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
