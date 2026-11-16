# final: prev:
# Packages are built against prev so the overlay does not recurse into itself.
final: prev:
import ./default.nix { pkgs = prev; }
