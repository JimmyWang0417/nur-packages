# Reads the gitignored hash file written by `nix run .#fetch-deveco`.
# That file records archive names and flat sha256 hashes. It has no URL.
# Pure evaluation cannot see a gitignored working-tree file, so this returns
# null until the build is evaluated with --impure from the repository.
let
  readEnv = name:
    let
      attempt = builtins.tryEval (builtins.getEnv name);
    in
    if attempt.success then attempt.value else "";

  explicit = readEnv "DEVECO_SOURCES";
  pwd = readEnv "PWD";
  candidate =
    if explicit != "" then
      explicit
    else if pwd != "" then
      pwd + "/pkgs/deveco-studio/sources.local.nix"
    else
      "";
in
if candidate != "" && builtins.pathExists candidate then import candidate else null
