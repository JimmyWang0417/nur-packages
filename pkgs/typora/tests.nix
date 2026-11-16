{
  runCommand,
  python3,
  desktop-file-utils,
  xorg-server,
  xwininfo,
  dejavu_fonts,
  package,
}:
{
  layout =
    runCommand "typora-layout"
      {
        nativeBuildInputs = [
          python3
          desktop-file-utils
        ];
      }
      ''
        test -x ${package}/bin/typora
        test "${package.pname}" = typora
        test -f ${package}/share/licenses/typora/typora-copyright
        desktop-file-validate ${package}/share/applications/typora.desktop
        grep -qx 'Name=Typora' ${package}/share/applications/typora.desktop
        test -f ${package}/share/icons/hicolor/128x128/apps/typora.png
        python3 ${./layout-test.py} ${package}
        touch "$out"
      '';

  runtime =
    runCommand "typora-runtime"
      {
        nativeBuildInputs = [ python3 ];
      }
      ''
        python3 ${./runtime-test.py} ${package}/bin/typora
        touch "$out"
      '';

  gui =
    runCommand "typora-gui"
      {
        nativeBuildInputs = [
          python3
          xorg-server
          xwininfo
        ];
      }
      ''
        python3 ${./gui-test.py} ${package}/bin/typora ${dejavu_fonts}/share/fonts
        touch "$out"
      '';
}
