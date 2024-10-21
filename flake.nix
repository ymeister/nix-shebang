{
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
          project = pkgs.callPackage ./default.nix { inherit pkgs; };
      in {
        packages = project;
      }
    );
}
