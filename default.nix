{ pkgs ? import <nixpkgs> {}
, inputs ? {}
}:

with pkgs;

let cached-nix-shell-src = inputs.cached-nix-shell or ./deps/cached-nix-shell;
    cached-nix-shell = callPackage cached-nix-shell-src { inherit pkgs; };
    cached-nix-shell-bin = "${cached-nix-shell}/bin/cached-nix-shell";
    cached-nix-script = script:
        "'" + ''runCommand "''
      + "'" + ''"$exe"'' + "'"
      + ''" {} "mkdir -p $out/bin; ''
      + script "\${builtins.storePath '\"$path\"'}" ("$out/bin/" + "'" + ''"$exe"'' + "'")
      + ''"''
      + "'";
    cached-nix-script-shebang = script: ''
      args=()
      opts=()
      deps=()
      with=()
      module="{}"

      while [ "$#" -gt 0 ]; do
        case "$1" in
          "--")
            builtin shift
            args=("$@")
            break
            ;;
          "--module")
            builtin shift
            module="$1"
            ;;
          "--opts")
            builtin shift
            while [ "$#" -gt 0 ] && [[ "$1" != --* ]]; do
              opts+=("$1")
              builtin shift
            done
            continue
            ;;
          "--deps")
            builtin shift
            while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
              deps+=("$1")
              builtin shift
            done
            continue
            ;;
          "--with")
            builtin shift
            while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
              with+=("$1")
              builtin shift
            done
            continue
            ;;
          -*)
            opts+=("$1")
            ;;
          *)
            deps+=("$1")
            ;;
        esac
        builtin shift
      done

      src="$(readlink -f "''${args[0]}")"
      exe="$(basename "$src")"
      path="$(nix store add "$src")"
      args=("''${args[@]:1}")

      exec ${cached-nix-shell-bin} -p ${cached-nix-script script} "''${with[@]}" --exec "$exe" "''${args[@]}"
    '';

    nix-haskell-src = inputs.nix-haskell or ./deps/nix-haskell;
    nix-haskell = import nix-haskell-src { inherit pkgs; system = pkgs.system; };

    mkGhcWithPackages = gwp: ''''${('' + gwp + '' (pkgs: with pkgs; ['' + " '" + ''"$(echo "''${deps[@]}")"'' + "' " + '']))}'';

    ghcWithPackages = module:
      let nh = nix-haskell ({ src = ./.; } // module);
          compiler = nh.config.compiler-nix-name;
          ghcWithPackages-nix = writeText "ghc-with-packages.nix" ''
            depsStr: module:
              let nix-haskell = import ${toString nix-haskell-src} { system = "${pkgs.system}"; };
                  nh = nix-haskell {};
                  depNames = builtins.filter builtins.isString (builtins.split " " depsStr);
              in (nh.ghcWithPackages.haskell-nix ([{
                compiler-nix-name = "${compiler}";
                cabalProjectLocal =
                  ${"''"}
                    if impl(ghc == 9.14.*)
                      allow-newer:
                          *:base
                        , *:template-haskell
                        , *:ghc-experimental
                        , *:ghc-internal
                        , *:ghc-bignum
                        , *:containers
                      constraints:
                          base < 4.23
                        , template-haskell < 2.25
                        , ghc-experimental < 9.1500
                        , ghc-internal < 9.1500
                  ${"''"};
              }] ++ (if builtins.isList module then module else [module]))) depNames
          '';
      in ''''${(import ${ghcWithPackages-nix} "'' + "'" + ''"$(echo "''${deps[@]}")"'' + "'" + ''" '' + "'" + ''"$module"'' + "'" + '')}'';

    ghcWithPackages' = mkGhcWithPackages "haskellPackages.ghcWithPackages";

    haskell-script = ghc: input: output: ''${ghc}/bin/ghc'' + " '" + ''"$(echo "''${opts[@]}")"'' + "' " + ''-o ${output} ${input}'';
    haskell-repl = ghc: input: output: ''echo ${ghc}/bin/ghci'' + " '" + ''"$src"'' + "' " + ''> ${output}; chmod +x ${output}'';

    mkHaskell = ghc: symlinkJoin {
      name = "nix-haskell-shebang";
      paths = [
        (
          writeScriptBin "nix-haskell-shebang" ''
            #!/usr/bin/env bash

            ${cached-nix-script-shebang (haskell-script ghc)}
          ''
        )
        (
          writeScriptBin "nix-haskell-repl" ''
            #!/usr/bin/env bash

            ${cached-nix-script-shebang (haskell-repl ghc)}
          ''
        )
      ];
    };

in {
  haskell = {
    nix-haskell = mkHaskell (ghcWithPackages {});
    nixpkgs = mkHaskell ghcWithPackages';
  };
}
