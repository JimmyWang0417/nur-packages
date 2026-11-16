{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "crm";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "wtklbm";
    repo = "crm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OwDBDNTb4s0Rb9yXef9sWYBi9W/+Rg/ZpRtqqPeg8L0=";
  };

  # Tag v0.2.2 ships no Cargo.lock. cargoLock vendors from the file beside
  # this expression. postUnpack places that lock into the unpacked tree while
  # it is still writable. This is the approach in
  # /nix/store/a9zjvqwxm8wfrmdw24cq0y1689lmjij6-crm-0.2.2.drv.
  cargoLock.lockFile = ./Cargo.lock;
  postUnpack = ''
    cp ${./Cargo.lock} "$sourceRoot/Cargo.lock"
  '';

  meta = {
    description = "Cargo registry manager";
    homepage = "https://github.com/wtklbm/crm";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "crm";
  };
})
