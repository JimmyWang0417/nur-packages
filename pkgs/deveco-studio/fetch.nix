{ lib, writeShellApplication, python3, hdx }:
writeShellApplication {
  name = "fetch-deveco";
  runtimeInputs = [ python3 hdx ];
  text = ''
    export HDX=${lib.getExe hdx}
    exec python3 ${./fetch_deveco.py} "$@"
  '';
}
