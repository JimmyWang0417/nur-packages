{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  tmux,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "botmux";
  version = "3.59.15";

  src = fetchurl {
    url = "https://github.com/deepcoldy/botmux/releases/download/v${finalAttrs.version}/botmux-linux-x64";
    hash = "sha256-+z8lNOjxa8EgCJ9+KmUZfUQV7le4oXuD9DL2YZCxkIs=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # Bun's compiled executable appends the program to the ELF. strip would delete it.
  dontStrip = true;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/.botmux-unwrapped"
    makeWrapper "$out/bin/.botmux-unwrapped" "$out/bin/botmux" \
      --prefix PATH : "${lib.makeBinPath [ tmux ]}"
    runHook postInstall
  '';

  meta = {
    description = "Bridge Feishu/Lark chats to coding CLIs running in tmux";
    homepage = "https://github.com/deepcoldy/botmux";
    license = lib.licenses.mit;
    mainProgram = "botmux";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
