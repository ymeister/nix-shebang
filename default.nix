{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let nix-thunk = import ./deps/nix-thunk { inherit pkgs; };
    deps = with nix-thunk; mapSubdirectories thunkSource ./deps;

    cached-nix-shell = callPackage deps.cached-nix-shell { inherit pkgs; };
    cached-nix-shell-bin = "${cached-nix-shell}/bin/cached-nix-shell";
    cached-nix-script = script: "'" + ''runCommand "'' + "'" + ''"$exe"'' + "'" + ''" {} "mkdir -p $out/bin; ${script "\${builtins.storePath '\"$path\"'}" ("$out/bin/" + "'" + ''"$exe"'' + "'")}"'' + "'";
    cached-nix-script-shebang = script: ''
      while [ "$#" -gt 0 ]; do
        case "$1" in
          "--")
            builtin shift
            args=("''${args[@]}" "$@")
            break
            ;;
          *)
            deps=("''${deps[@]}" "$1")
            ;;
        esac
        builtin shift
      done

      src="$(readlink -f "''${args[0]}")"
      exe="$(basename "$src")"
      path="$(nix store add "$src")"
      args=("''${args[@]:1}")

      exec ${cached-nix-shell-bin} -p ${cached-nix-script script} --exec "$exe" "''${args[@]}"
    '';

    ghcWithPackages = ''''${(haskellPackages.ghcWithPackages (pkgs: with pkgs; ['' + " '" + ''"$(echo "''${deps[@]}")"'' + "' " + '']))}/bin/ghc'';
    haskell-script = input: output: "${ghcWithPackages} -O2 -threaded -rtsopts -with-rtsopts=-N -o ${output} ${input}";

in {
  haskell = writeScriptBin "nix-haskell-shebang" ''
    #!/bin/sh

    ${cached-nix-script-shebang haskell-script}
  '';
}
