```
#!/usr/bin/env nix
#!nix shell --no-write-lock-file github:ymeister/nix-shebang#haskell --command sh -c ``nix-haskell-shebang shh -- "$@"`` sh

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
