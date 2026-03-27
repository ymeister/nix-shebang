#!/usr/bin/env nix
#!nix shell --no-write-lock-file .#haskell.nixpkgs --command sh -c ``nix-haskell-shebang --opts -O2 --deps shh -- "$@"`` sh

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
