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

    ghcWithPackages = ''''${(haskellPackages.ghcWithPackages (pkgs: with pkgs; ['' + " '" + ''"$(echo "''${deps[@]}")"'' + "' " + '']))}'';
    haskell-script = input: output: "${ghcWithPackages}/bin/ghc -O2 -threaded -rtsopts -with-rtsopts=-N -o ${output} ${input}";
    haskell-repl = input: output: "echo ${ghcWithPackages}/bin/ghci ${input} > ${output}; chmod +x ${output}";

in {
  haskell = symlinkJoin {
    name = "nix-haskell-shebang";
    paths = [
      (
        writeScriptBin "nix-haskell-shebang" ''
          #!/bin/sh

          ${cached-nix-script-shebang haskell-script}
        ''
      )
      (
        writeScriptBin "nix-haskell-repl" ''
          #!/bin/sh

          ${cached-nix-script-shebang haskell-repl}
        ''
      )
    ];
  };
}
