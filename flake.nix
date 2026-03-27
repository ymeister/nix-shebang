{
  inputs = {
    cached-nix-shell = {
      url = "git+file:./deps/cached-nix-shell?submodules=1";
      flake = false;
    };

    nix-haskell.url = "git+file:./deps/nix-haskell?submodules=1";

    nixpkgs.follows = "nix-haskell/nixpkgs";
  };

  outputs = inputs@{ self, ... }:
    let nixpkgs = if inputs ? "nixpkgs" then inputs.nixpkgs else builtins.getFlake "nixpkgs";
        eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      packages = eachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
            project = pkgs.callPackage ./default.nix { inherit pkgs inputs; };
        in project
      );
    };
}
