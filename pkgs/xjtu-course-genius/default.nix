{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  atk,
  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libepoxy,
  pango,
  libx11,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xjtu-course-genius";
  version = "4.6.1";

  src = fetchurl {
    url = "https://github.com/Hz162/XJTU-Course-Genius/releases/download/v${finalAttrs.version}/XJTU-Course-Genius-linux-x64.deb";
    hash = "sha256-5ql+Jd9/GtgIC7g8qdX9qyKWnR59rs8NkH04masEx/s=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libepoxy
    pango
    stdenv.cc.cc.lib
    libx11
    zlib
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

    mkdir -p "$out/opt" "$out/bin" "$out/share"
    cp -a opt/xjtu-course-genius "$out/opt/xjtu-course-genius"
    cp -a usr/share/icons "$out/share/icons"
    install -Dm644 usr/share/applications/xjtu-course-genius.desktop \
      "$out/share/applications/xjtu-course-genius.desktop"
    substituteInPlace "$out/share/applications/xjtu-course-genius.desktop" \
      --replace-fail "Exec=/opt/xjtu-course-genius/xjtu_course_genius" "Exec=xjtu-course-genius"

    chmod +x "$out/opt/xjtu-course-genius/xjtu_course_genius" \
      "$out/opt/xjtu-course-genius/xjtu-genius"

    makeWrapper "$out/opt/xjtu-course-genius/xjtu_course_genius" "$out/bin/xjtu-course-genius"
    ln -s "$out/opt/xjtu-course-genius/xjtu-genius" "$out/bin/xjtu-genius"

    runHook postInstall
  '';

  meta = {
    description = "西安交通大学选课助手";
    homepage = "https://github.com/Hz162/XJTU-Course-Genius";
    # Free software; upstream has not published a formal license certificate yet.
    license = lib.licenses.free;
    mainProgram = "xjtu-course-genius";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
