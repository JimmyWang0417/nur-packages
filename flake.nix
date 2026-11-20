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
      # deveco-studio stays out of default.nix. That file is what CI builds
      # and what checks instantiate. fetch-deveco is an app, not a package,
      # so the CI package loop does not build it or download DevEco archives.
      packages = forAllSystems (pkgs:
        (import ./default.nix { inherit pkgs; })
        // {
          deveco-studio = pkgs.callPackage ./pkgs/deveco-studio { };
        }
      );

      apps = forAllSystems (pkgs: {
        fetch-deveco = {
          type = "app";
          program = "${pkgs.callPackage ./pkgs/deveco-studio/fetch.nix { }}/bin/fetch-deveco";
        };
      });

      overlays.default = final: prev:
        (import ./default.nix { pkgs = prev; })
        // {
          deveco-studio = prev.callPackage ./pkgs/deveco-studio { };
        };

      checks = forAllSystems (pkgs:
        nixpkgs.lib.mapAttrs' (
          name: value: nixpkgs.lib.nameValuePair "package-${name}" value
        ) (import ./default.nix { inherit pkgs; })
      );
    };
}
