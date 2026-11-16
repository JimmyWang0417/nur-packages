{
  appimageTools,
  fetchurl,
  lib,
  makeDesktopItem,
}:
let
  pname = "animeko";
  version = "6.4.0";
  src = fetchurl {
    url = "https://github.com/open-ani/animeko/releases/download/v${version}/ani-${version}-linux-x86_64.appimage";
    hash = "sha256-VnnqjYaiOIPgIhVs8+7F4FrvRZ8ld89xDlp2b2QQTyc=";
  };
  contents = appimageTools.extract { inherit pname version src; };
  desktopItem = makeDesktopItem {
    name = "animeko";
    desktopName = "Animeko";
    comment = "集找番、追番、看番的一站式弹幕追番平台";
    exec = "animeko";
    icon = "animeko";
    terminal = false;
    categories = [
      "AudioVideo"
      "Player"
      "Video"
    ];
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${desktopItem}/share/applications/animeko.desktop $out/share/applications/animeko.desktop
    install -Dm644 ${contents}/icon.png $out/share/icons/hicolor/512x512/apps/animeko.png
  '';

  meta = {
    description = "集找番、追番、看番的一站式弹幕追番平台";
    homepage = "https://github.com/open-ani/animeko";
    license = lib.licenses.agpl3Plus;
    mainProgram = "animeko";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
