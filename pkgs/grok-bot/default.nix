{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeShellWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libGL,
  libappindicator-gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libsecret,
  libuuid,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  vulkan-loader,
  wayland,
  xdg-utils,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
}:
let
  version = "1.1.0";
  commit = "83d46d618ef4c12afa17edd8e3c29d6caf046d17";
  artifacts = {
    x86_64-linux = {
      url = "https://downloads.cursor.com/grokbot/stable/${commit}/linux/x64/grok-bot_1.1.0_amd64.deb";
      hash = "sha256-WwL7IVED7e2U7J84GnkNcfZyfwF2gcft0bVvK4z6Vy0=";
    };
    aarch64-linux = {
      url = "https://downloads.cursor.com/grokbot/stable/${commit}/linux/arm64/grok-bot_1.1.0_arm64.deb";
      hash = "sha256-L6IH7ON6yNlfUN5Jm8VcVTQHJfMtBuADzNyCABU5jxc=";
    };
  };
  artifact =
    artifacts.${stdenv.hostPlatform.system}
      or (throw "grok-bot: unsupported system ${stdenv.hostPlatform.system}");

  runtimeLibs = [
    libGL
    libappindicator-gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libsecret
    libxkbcommon
    vulkan-loader
    wayland
    (lib.getLib systemd)
  ];
in
stdenv.mkDerivation {
  pname = "grok-bot";
  inherit version;

  src = fetchurl {
    inherit (artifact) url hash;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeShellWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libuuid
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
  ] ++ runtimeLibs;

  runtimeDependencies = runtimeLibs;

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/grok-bot"
    cp -a "opt/Grok Bot/." "$out/lib/grok-bot/"

    rm -f "$out/lib/grok-bot/chrome-sandbox"

    if [ -e "$out/lib/grok-bot/libvulkan.so.1" ]; then
      rm -f "$out/lib/grok-bot/libvulkan.so.1"
      ln -s "${lib.getLib vulkan-loader}/lib/libvulkan.so.1" "$out/lib/grok-bot/libvulkan.so.1"
    fi

    found_icon=
    for icon in usr/share/icons/hicolor/*/apps/*; do
      [ -f "$icon" ] || continue
      relative="''${icon#usr/share/icons/hicolor/}"
      size="''${relative%%/*}"
      name="$(basename "$icon")"
      case "$name" in
        sand.*) name="grok-bot.''${name##*.}" ;;
      esac
      install -Dm644 "$icon" "$out/share/icons/hicolor/$size/apps/$name"
      found_icon=1
    done
    if [ -z "$found_icon" ]; then
      echo "grok-bot: no hicolor icon in the .deb" >&2
      exit 1
    fi

    if [ -f usr/share/applications/grok-bot.desktop ]; then
      desktop=usr/share/applications/grok-bot.desktop
    elif [ -f usr/share/applications/sand.desktop ]; then
      desktop=usr/share/applications/sand.desktop
    else
      echo "grok-bot: no desktop file in the .deb" >&2
      exit 1
    fi
    install -Dm644 "$desktop" "$out/share/applications/grok-bot.desktop"
    sed -i \
      -e "s|^Exec=.*|Exec=$out/bin/grok-bot %U|" \
      -e "s|^Icon=.*|Icon=grok-bot|" \
      "$out/share/applications/grok-bot.desktop"

    runHook postInstall
  '';

  preFixup = ''
    if [ -x "$out/lib/grok-bot/grok-bot" ]; then
      upstream_executable="$out/lib/grok-bot/grok-bot"
    elif [ -x "$out/lib/grok-bot/sand" ]; then
      upstream_executable="$out/lib/grok-bot/sand"
    else
      echo "grok-bot: no launcher binary in the .deb" >&2
      exit 1
    fi

    makeShellWrapper "$upstream_executable" "$out/bin/grok-bot" \
      "''${gappsWrapperArgs[@]}" \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --set-default CHROME_DESKTOP grok-bot.desktop \
      --add-flags "''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-wayland-ime=true}}"

    ln -s grok-bot "$out/bin/sand"
  '';

  passthru = {
    inherit commit artifacts;
  };

  meta = {
    description = "xAI Grok Bot desktop agent";
    homepage = "https://x.ai/bot";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames artifacts;
    mainProgram = "grok-bot";
  };
}
