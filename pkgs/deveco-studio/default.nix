# DevEco Studio for Linux, assembled the way alex3236/devecostudio-linux
# tag v26.0.0 does (IDEA 2026.1.3). The version below is the Huawei version
# from that project's latest GitHub release, without the Arch package
# release. scripts/update.py kind github-version rewrites only this string.
#
# The two DevEco archives are not fetched by URL. When this package is
# evaluated impurely and this machine already has an hdx login, the build
# runs the hdx package, refreshes that login, and downloads the archives.
# Signed URLs stay in that process. A pure evaluation does not call hdx.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  requireFile,
  callPackage,
  runCommand,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gawk,
  gnutar,
  gzip,
  unzip,
  libarchive,
  p7zip,
  python3,
  jq,
  patchelf,
  binutils,
  hdx,
  # sudo nixos-rebuild often clears HOME. A normal login keeps it.
  # Reading the NixOS user option from the installing module loops.
  home ? let
    envHome = builtins.getEnv "HOME";
  in if envHome != "" && envHome != "/root" then envHome else "/home/jimmywang0417",
  macZip ? null,
  cliZip ? null,
}:
let
  version = "26.0.0.851";
  ideaVersion = "2026.1.3";
  upstreamRev = "f7afbf391f5ea96fce6a1034d835274d6327bfe3"; # tag v26.0.0
  givenMac = macZip;
  givenCli = cliZip;
  direct = givenMac != null && givenCli != null;

  credentials =
    if home == "" then "" else "${home}/.config/hdx/credentials.json";
  impure = builtins.pathExists /etc/hostname;
  haveCreds = credentials != "" && builtins.pathExists credentials;
  liveFetch = !direct && impure && haveCreds;

  sources = if direct || liveFetch then null else import ./sources.nix;
  hashOk = value: builtins.match "sha256-[A-Za-z0-9+/]{43}=" value != null;
  nameOk = value: builtins.match "[A-Za-z0-9._+-]+" value != null;
  entryOk = entry: entry ? name && entry ? hash && nameOk entry.name && hashOk entry.hash;
  sourcesOk = sources != null && sources ? mac && sources ? cli
    && entryOk sources.mac && entryOk sources.cli;

  loginMessage = "run `hdx auth login` on this machine";
  skipMessage = ''
    DevEco Studio was not downloaded. Re-run `nixos-rebuild switch --impure` after `hdx auth login` on this machine.
  '';

  fetchTool = callPackage ./fetch.nix { inherit hdx; };

  archive = entry: requireFile {
    name = entry.name;
    hash = entry.hash;
    hashMode = "flat";
    message = ''
      ${entry.name} is not in the Nix store.
      ${loginMessage}
      Then run `nix build --impure .#deveco-studio`.
    '';
  };

  tools = [
    bash
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    gnutar
    gzip
    unzip
    libarchive
    p7zip
    python3
    jq
    patchelf
    binutils
  ];

  upstream = fetchFromGitHub {
    owner = "alex3236";
    repo = "devecostudio-linux";
    rev = upstreamRev;
    hash = "sha256-KQ6DCwurkFOSr/Fkboraiw/6EIGQG2PZS3DmKLJlhOU=";
  };
  idea = fetchurl {
    url = "https://download.jetbrains.com/idea/idea-${ideaVersion}.tar.gz";
    sha256 = "a6f049716da1d09d9e0ec1500c60bf01a5ff8a0fe2419178dd1ff2fdb2b77563";
  };
  cpython = fetchurl {
    url = "https://github.com/astral-sh/python-build-standalone/releases/download/20250409/cpython-3.12.10+20250409-x86_64-unknown-linux-gnu-install_only.tar.gz";
    sha256 = "e9cf6f7da499a4400ba30ae1da8f7ef25ce97827bd8c1084717aa05438035186";
  };

  stub = mode: message: stdenvNoCC.mkDerivation {
    pname = "deveco-studio";
    inherit version;
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      echo ${lib.escapeShellArg message} >&2
      exit 1
    '';
    passthru = {
      installMode = mode;
      installMessage = message;
      archivesReady = false;
    };
    meta = {
      description = "Huawei DevEco Studio assembled for Linux";
      homepage = "https://github.com/alex3236/devecostudio-linux";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "devecostudio";
    };
  };

  assemble = mac: cli: stdenv.mkDerivation {
    pname = "deveco-studio";
    inherit version;

    dontUnpack = true;
    dontStrip = true;

    nativeBuildInputs = tools;

    macZip = mac;
    cliZip = cli;
    inherit upstream idea cpython;

    buildPhase = ''
      runHook preBuild
      work=$TMPDIR/deveco-src
      rm -rf "$work"
      mkdir -p "$work/build/downloads" "$TMPDIR/home"
      cp -a "$upstream"/. "$work"/
      chmod +x "$work/build.sh"
      cp -a "$macZip" "$work/devecostudio-mac.zip"
      cp -a "$cliZip" "$work/commandline-tools-linux-x64.zip"
      cp -a "$idea" "$work/build/downloads/idea-${ideaVersion}.tar.gz"
      cp -a "$cpython" "$work/build/downloads/cpython-3.12.10+20250409-x86_64-unknown-linux-gnu-install_only.tar.gz"
      (
        cd "$work"
        export HOME=$TMPDIR/home
        bash ./build.sh --no-tarball
      )
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -a "$TMPDIR/deveco-src/build/pkg/." "$out"/
      test -d "$out/opt/devecostudio"
      while IFS= read -r -d "" link; do
        target=$(readlink "$link")
        case "$target" in
          /opt/devecostudio*)
            ln -sfn "$out/opt/devecostudio''${target#/opt/devecostudio}" "$link"
            ;;
        esac
      done < <(find "$out" -type l -print0)
      while IFS= read -r file; do
        sed -i "s|/opt/devecostudio|$out/opt/devecostudio|g" "$file"
      done < <(grep -RIlF /opt/devecostudio "$out" || true)
      mkdir -p "$out/bin"
      ln -sfn "$out/opt/devecostudio/bin/devecostudio.sh" "$out/bin/devecostudio"
      for tool in hvigorw ohpm hstack; do
        ln -sfn "$out/opt/devecostudio/tools/bin/$tool" "$out/bin/$tool"
      done
      ln -sfn "$out/opt/devecostudio/tools/bin/codelinter" "$out/bin/hcodelinter"
      ln -sfn "$out/opt/devecostudio/tools/bin/Emulator" "$out/bin/hemulator"
      ln -sfn "$out/opt/devecostudio/tools/bin/arktsdoc" "$out/bin/harktsdoc"
      ln -sfn "$out/opt/devecostudio/sdk/default/openharmony/toolchains/hdc" "$out/bin/hdc"
      runHook postInstall
    '';

    passthru = {
      installMode = "install";
      installMessage = "";
      archivesReady = true;
    };
    meta = {
      description = "Huawei DevEco Studio assembled for Linux";
      homepage = "https://github.com/alex3236/devecostudio-linux";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      mainProgram = "devecostudio";
    };
  };

  fetched = runCommand "deveco-archives-${version}-${toString builtins.currentTime}" {
    nativeBuildInputs = [ fetchTool ];
    preferLocalBuild = true;
    allowSubstitutes = "0";
    __noChroot = true;
    HOME = home;
    XDG_CONFIG_HOME = "${home}/.config";
  } ''
    if [ ! -s "$HOME/.config/hdx/credentials.json" ]; then
      echo ${lib.escapeShellArg loginMessage} >&2
      exit 1
    fi
    mkdir -p "$out"
    fetch-deveco --output-dir "$out"
    if grep -q '://' "$out/.hashes"; then
      echo "refusing a download URL" >&2
      exit 1
    fi
  '';
in
if direct then assemble givenMac givenCli
else if liveFetch then assemble "${fetched}/mac.zip" "${fetched}/cli.zip"
else if sourcesOk then assemble (archive sources.mac) (archive sources.cli)
else if impure then stub "login" loginMessage
else stub "skip" skipMessage
