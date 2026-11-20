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
  curl,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libglvnd,
  libnotify,
  libsecret,
  libsoup_3,
  webkitgtk_4_1,
  libxkbcommon,
  libxkbfile,
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
  pname = "trae-cn";
  # CDN path uses this build id. The China manifest's app version for it is 3.4.22.
  version = "2.3.105403";

  src = fetchurl {
    url = "https://lf-cdn.trae.com.cn/obj/trae-com-cn/pkg/app/releases/stable/${finalAttrs.version}/linux/TRAE_CN-linux-x64.deb";
    hash = "sha256-LSBz+rcHU7oKSzvyaLqKHr+To/rxQsKPNETB5UgXrmg=";
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
    curl
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libglvnd
    libnotify
    libsecret
    libsoup_3
    webkitgtk_4_1
    libxkbcommon
    libxkbfile
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

  # Upstream ships musl builds of native addons beside the glibc ones.
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

    mkdir -p "$out/bin" "$out/share"
    cp -a usr/share/trae-cn "$out/share/trae-cn"
    install -Dm644 usr/share/pixmaps/trae-cn.png \
      "$out/share/pixmaps/trae-cn.png"
    install -Dm644 usr/share/applications/trae-cn.desktop \
      "$out/share/applications/trae-cn.desktop"
    install -Dm644 usr/share/applications/trae-cn-url-handler.desktop \
      "$out/share/applications/trae-cn-url-handler.desktop"
    substituteInPlace \
      "$out/share/applications/trae-cn.desktop" \
      "$out/share/applications/trae-cn-url-handler.desktop" \
      --replace-fail "/usr/share/trae-cn/bin/trae-cn" "trae-cn"
    install -Dm644 usr/share/bash-completion/completions/trae-cn \
      "$out/share/bash-completion/completions/trae-cn"

    chmod 755 "$out/share/trae-cn/bin/trae-cn" \
      "$out/share/trae-cn/trae-cn" \
      "$out/share/trae-cn/chrome-sandbox" \
      "$out/share/trae-cn/chrome_crashpad_handler"

    makeWrapper "$out/share/trae-cn/bin/trae-cn" "$out/bin/trae-cn" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix LD_LIBRARY_PATH : "$out/share/trae-cn:${
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
    description = "Trae CN, the official China Linux desktop for the Trae IDE";
    homepage = "https://www.trae.com.cn/";
    license = lib.licenses.unfree;
    mainProgram = "trae-cn";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
