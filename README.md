# nix-shebang

Run scripts as executables with automatic dependency management via Nix.

Currently supports Haskell. More languages are planned.

## How it works

Nix flakes cache evaluation results but do not cache `nix shell --expr`. We exploit this by using a flake to instantly bring in [cached-nix-shell](https://github.com/xzfc/cached-nix-shell), which can cache arbitrary Nix expressions. The script is then compiled and cached on first run via `cached-nix-shell`.

## Haskell

Add a shebang to your Haskell file:

```haskell
#!/usr/bin/env nix
#!nix shell --no-write-lock-file github:ymeister/nix-shebang#haskell.nix-haskell --command sh -c ``nix-haskell-shebang --opts -O2 --deps shh -- "$@"`` sh

{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE TemplateHaskell #-}

import System.Environment
import Shh

$(loadEnv SearchPath)

main :: IO ()
main = do
  args <- getArgs
  if null args then do
    echo "Hello World!"
  else do
    echo $ "Hello" : args
```

Then make it executable and run it:

```sh
chmod +x script.hs
./script.hs
```

### Shebang options

| Option | Description |
|---|---|
| `--deps <packages...>` | Haskell package dependencies |
| `--opts <flags...>` | GHC compiler flags (e.g. `-O2`, `-threaded`) |
| `--with <packages...>` | Non-Haskell system dependencies from nixpkgs |
| `--module <expr>` | Nix-haskell module override as a raw Nix expression (repeatable) |
| `--` | Separator between shebang args and script args |

Bare positional arguments are treated as `--deps`.

### Packages

Two variants are available via the flake:

- **`haskell.nix-haskell`** -- Uses [haskell.nix](https://github.com/input-output-hk/haskell.nix) for dependency resolution. Supports `--module` for overrides like custom compilers and cabal project settings.
- **`haskell.nixpkgs`** -- Uses `haskellPackages.ghcWithPackages` from nixpkgs.

### Commands

Each package provides two commands:

- **`nix-haskell-shebang`** -- Compiles and runs the script.
- **`nix-haskell-repl`** -- Opens GHCi with the script and its dependencies loaded.
