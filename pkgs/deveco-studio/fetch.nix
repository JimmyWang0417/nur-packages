{ writeShellApplication, python3 }:
writeShellApplication {
  name = "fetch-deveco";
  runtimeInputs = [ python3 ];
  text = ''
    exec python3 ${./fetch_deveco.py} "$@"
  '';
}
