{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  atk,
  cairo,
  dbus-glib,
  gdk-pixbuf,
  glib,
  gtk2,
  libudev0-shim,
  nspr,
  nss,
  pango,
  libx11,
  libxdamage,
  libxext,
  libxtst,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "easyconnect";
  version = "7.6.7.3";

  src = fetchurl {
    url = "https://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb";
    hash = "sha256-rmI8bcA1T/h6/vu3cN5QE7/ZQwUcmmU7k9twglOy8NM=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    dbus-glib
    gdk-pixbuf
    glib
    gtk2
    libudev0-shim
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    libx11
    libxdamage
    libxext
    libxtst
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share" "$out/bin"
    cp -a usr/share/sangfor "$out/share/sangfor"
    chmod +x "$out/share/sangfor/EasyConnect/EasyConnect"

    if [ -f usr/share/pixmaps/EasyConnect.png ]; then
      install -Dm644 usr/share/pixmaps/EasyConnect.png \
        "$out/share/icons/hicolor/256x256/apps/easyconnect.png"
    fi

    if [ -f usr/share/applications/EasyConnect.desktop ]; then
      install -Dm644 usr/share/applications/EasyConnect.desktop \
        "$out/share/applications/easyconnect.desktop"
      substituteInPlace "$out/share/applications/easyconnect.desktop" \
        --replace-quiet "/usr/share/sangfor/EasyConnect/EasyConnect" "easyconnect" \
        --replace-quiet "Icon=EasyConnect" "Icon=easyconnect"
    fi

    makeWrapper "$out/share/sangfor/EasyConnect/EasyConnect" "$out/bin/easyconnect" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libudev0-shim ]}"
    ln -s easyconnect "$out/bin/EasyConnect"

    runHook postInstall
  '';

  meta = {
    description = "深信服 EasyConnect SSL VPN 客户端";
    homepage = "https://www.sangfor.com.cn/";
    license = lib.licenses.unfree;
    mainProgram = "easyconnect";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
