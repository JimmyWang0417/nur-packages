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

  # Tag v0.2.2 ships no Cargo.lock. Copy the lock into the source before
  # cargoSetupPostPatchHook checks it, and vendor crates from the same file.
  prePatch = ''
    chmod u+w .
    cp ${./Cargo.lock} Cargo.lock
  '';
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
