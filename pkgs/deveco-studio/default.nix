# DevEco Studio for Linux, assembled the way alex3236/devecostudio-linux
# tag v26.0.0 does (pkgver 26.0.0.851, IDEA 2026.1.3):
#   Mac DevEco zip + Linux command-line tools zip + JetBrains IDEA.
# The Huawei archives are not fetched here. Their URLs are signed and
# short-lived, and the same version can be republished with different bytes.
# .github/workflows/deveco.yml downloads them with hdx in one job, then
# passes the files in. hdx's login is GitHub secret HDX_CREDENTIALS, the
# contents of ~/.config/hdx/credentials.json after one local `hdx auth login`.
# That login asks for a one-time SMS code, so Actions only refreshes the
# stored file. The previewer stays unavailable.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
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
  macZip ? null,
  cliZip ? null,
}:
let
  version = "26.0.0.851";
  ideaVersion = "2026.1.3";
  zipsPresent = macZip != null && cliZip != null;
  upstreamRev = "f7afbf391f5ea96fce6a1034d835274d6327bfe3"; # tag v26.0.0

  missing = stdenvNoCC.mkDerivation {
    pname = "deveco-studio";
    inherit version;
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      cat <<'EOF' >&2
DevEco Studio needs the Mac zip and the Linux command-line-tools zip.
GitHub Actions downloads both with hdx and builds them in
.github/workflows/deveco.yml. Add repository secret HDX_CREDENTIALS:
the contents of ~/.config/hdx/credentials.json after one local
`hdx auth login`. Do not commit that file.
EOF
      exit 1
    '';
    meta = {
      description = "Huawei DevEco Studio assembled for Linux";
      homepage = "https://developer.huawei.com/consumer/cn/deveco-studio/";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "devecostudio";
    };
  };

  full = stdenv.mkDerivation {
    pname = "deveco-studio";
    inherit version;

    dontUnpack = true;
    dontStrip = true;

    nativeBuildInputs = [
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

    macZip = macZip;
    cliZip = cliZip;
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

    meta = {
      description = "Huawei DevEco Studio assembled for Linux";
      homepage = "https://developer.huawei.com/consumer/cn/deveco-studio/";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      mainProgram = "devecostudio";
    };
  };
in
if zipsPresent then full else missing
