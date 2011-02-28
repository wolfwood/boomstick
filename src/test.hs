import Language.Dot
import Language.Dot.Syntax
import Language.Dot.Parser

import Data.Either

import IO

main = do
    b <- hGetContents stdin
    case parseDot "fi" b of
      Left err -> putStrLn $ show err
      --Right g -> putStrLn $ show $ pp g
      Right g -> putStrLn $ renderDot g
