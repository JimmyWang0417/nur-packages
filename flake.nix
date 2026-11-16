{
  description = "JimmyWang0417 NUR packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }));
    in
    {
      packages = forAllSystems (pkgs: import ./default.nix { inherit pkgs; });

      overlays.default = final: prev: import ./default.nix { pkgs = prev; };

      checks = forAllSystems (pkgs:
        nixpkgs.lib.mapAttrs' (
          name: value: nixpkgs.lib.nameValuePair "package-${name}" value
        ) (import ./default.nix { inherit pkgs; })
      );
    };
}
