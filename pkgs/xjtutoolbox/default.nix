{
  appimageTools,
  fetchurl,
  lib,
}:
let
  pname = "xjtutoolbox";
  version = "1.4.1";
  src = fetchurl {
    url = "https://github.com/yan-xiaoo/XJTUToolBox/releases/download/v${version}/XJTUToolbox-linux-x86_64.AppImage";
    hash = "sha256-xcNTscZ0+4wxTfr0evgtVAHx50yHTlQRzu/0eA9i2SA=";
  };
  contents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${contents}/xjtutoolbox.desktop $out/share/applications/xjtutoolbox.desktop
    install -Dm644 ${contents}/xjtutoolbox.png $out/share/icons/hicolor/256x256/apps/xjtutoolbox.png
    if [ ! -e "$out/bin/xjtutoolbox" ]; then
      ln -s "$out/bin/xjtutoolbox-${version}" "$out/bin/xjtutoolbox"
    fi
  '';

  meta = {
    description = "西安交通大学校园工具箱";
    homepage = "https://github.com/yan-xiaoo/XJTUToolBox";
    license = lib.licenses.gpl3Only;
    mainProgram = "xjtutoolbox";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
