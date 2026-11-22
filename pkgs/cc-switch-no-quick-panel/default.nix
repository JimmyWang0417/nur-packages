{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  cargo-tauri,
  jq,
  moreutils,
  nodejs,
  pkg-config,
  pnpm_12,
  pnpmConfigHook,
  wrapGAppsHook3,
  glib-networking,
  libayatana-appindicator,
  libsoup_3,
  openssl,
  sqlite,
  webkitgtk_4_1,
  zstd,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cc-switch-no-quick-panel";
  version = "4.0.39";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "farion1231";
    repo = "cc-switch";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5AsCFYVhfITAMOlZTq7h7ncUC5hRnCL6pRGZrhmG2S0=";
  };
  patches = [ ./hide-quick-panel.patch ];

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;
  cargoHash = "sha256-1K2SI+J6mS/6RS1jo2rDxuTbWJwBVbc0zR1Om3EozFg=";
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      ;
    pnpm = pnpm_12;
    fetcherVersion = 5;
    # This recipe only builds for x86_64 Linux. Skip other platforms' binaries.
    prePnpmInstall = "export pnpm_config_force_ignores_platform=false";
    hash = "sha256-05/MMdCjV6icTk36ZcFhuNj05331ygnR+Icz97AbOS8=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    moreutils
    nodejs
    pkg-config
    pnpmConfigHook
    pnpm_12
    wrapGAppsHook3
  ];
  buildInputs = [
    glib-networking
    libayatana-appindicator
    libsoup_3
    openssl
    sqlite
    webkitgtk_4_1
    zstd
  ];

  postPatch = ''
    jq '
      del(.build.beforeBuildCommand) |
      .bundle.createUpdaterArtifacts = false |
      .plugins.updater.endpoints = []
    ' src-tauri/tauri.conf.json | sponge src-tauri/tauri.conf.json

    substituteInPlace "$cargoDepsCopy"/*/libappindicator-sys-*/src/lib.rs \
      --replace-fail 'libayatana-appindicator3.so.1' '${libayatana-appindicator}/lib/libayatana-appindicator3.so.1'
  '';
  preBuild = ''
    pnpm run build:renderer
  '';
  tauriBuildFlags = [ "--ignore-version-mismatches" ];

  # Avoid LTO memory spikes on the shared CI runner. Upstream integration
  # tests include network and interactive desktop flows.
  env.CARGO_PROFILE_RELEASE_LTO = "false";
  doCheck = false;

  meta = {
    description = "CC Switch with its native Linux tray menu and no quick panel entry";
    homepage = "https://github.com/farion1231/cc-switch";
    license = lib.licenses.mit;
    mainProgram = "cc-switch";
    platforms = [ "x86_64-linux" ];
  };
})
