-- | Simple template module
-- Contains many constant bot commands.
module Lambdabot.Plugin.Misc.Dummy (dummyPlugin) where

import Lambdabot.Plugin
import Lambdabot.Plugin.Misc.Dummy.DocAssocs (docAssocs)
import Lambdabot.Util

import Data.Char
import qualified Data.ByteString.Char8 as P
import qualified Data.Map as M
import System.FilePath

dummyPlugin :: Module ()
dummyPlugin = newModule
    { moduleCmds = return
        $ (command "eval")
            { help = say "eval. Do nothing (perversely)"
            , process = const (return ())
            }
        : (command "choose")
            { help = say "choose. Lambdabot featuring AI power"
            , process = \args ->
                if null args then say "Choose between what?"
                    else say =<< (io . random . words $ args)
            }
        : [ (command cmd)
            { help = say (dummyHelp cmd)
            , process = mapM_ say . lines . op
            }
          | (cmd, op) <- dummylst
          ]

    , contextual = \msg -> case msg of
        "lisppaste2: url"  -> say "Haskell pastebin: http://lpaste.net/"
        _                  -> return ()
    }

dummyHelp :: String -> String
dummyHelp s = case s of
    "dummy"       -> "dummy. Print a string constant"
    "bug"         -> "bug. Submit a bug to GHC's trac"
    "id"          -> "id <arg>. The identity plugin"
    "show"        -> "show <foo>. Print \"<foo>\""
    "wiki"        -> "wiki <page>. URLs of Haskell wiki pages"
    "paste"       -> "paste. Paste page url"
    "docs"        -> "docs <lib>. Lookup the url for this library's documentation"
    "learn"       -> "learn. The learning page url"
    "haskellers"  -> "haskellers. Find other Haskell users"
    "botsnack"    -> "botsnack. Feeds the bot a snack"
    "get-shapr"   -> "get-shapr. Summon shapr instantly"
    "shootout"    -> "shootout. The debian language shootout"
    "faq"         -> "faq. Answer frequently asked questions about Haskell"
    "googleit"    -> "letmegooglethatforyou."
    "hackage"     -> "find stuff on hackage"
    _             -> "I'm sorry Dave, I'm afraid I don't know that command"

dummylst :: [(String, String -> String)]
dummylst =
    [("dummy"      , const "dummy")
    ,("bug"        , const "https://hackage.haskell.org/trac/ghc/newticket?type=bug")
    ,("id"         , (' ' :) . id)
    ,("show"       , show)
    ,("wiki"       , lookupWiki)
    ,("paste"      , const "Haskell pastebin: http://lpaste.net/")
    ,("docs"       , \x -> if null x
                           then docPrefix </> "index.html"
                           else lookupPackage docPrefix '-' "html" x)
    ,("learn"      , const "https://wiki.haskell.org/Learning_Haskell")
    ,("haskellers" , const "http://www.haskellers.com/")
    ,("botsnack"   , const ":)")
    ,("get-shapr"  , const "shapr!!")
    ,("shootout"   , const "http://benchmarksgame.alioth.debian.org/")
    ,("faq"        , const "The answer is: Yes! Haskell can do that.")
    ,("googleit"   , lookupGoogle)
    ,("hackage"    , lookupHackage)
    ,("thanks"     , const "you are welcome")
    ,("thx"        , const "you are welcome")
    ,("thank you"  , const "you are welcome")
    ,("ping"       , const "pong")
    ,("tic-tac-toe", const "how about a nice game of chess?")
    ]

lookupWiki :: String -> String
lookupWiki page = "https://wiki.haskell.org" </> spacesToUnderscores page
  where spacesToUnderscores = map (\c -> if c == ' ' then '_' else c)

lookupHackage :: String -> String
lookupHackage "" = "http://hackage.haskell.org"
lookupHackage xs = "http://hackage.haskell.org/package" </> xs

googlePrefix :: String
googlePrefix = "http://letmegooglethatforyou.com"

lookupGoogle :: String -> String
lookupGoogle "" = googlePrefix
lookupGoogle xs = googlePrefix </> "?q=" ++ quote xs
 where
    quote = map (\x -> if x == ' ' then '+' else x)

docPrefix :: String
docPrefix = "http://haskell.org/ghc/docs/latest/html/libraries"

lookupPackage :: String -> Char -> String -> String -> String
lookupPackage begin sep end x'' = 
    case M.lookup (P.pack x') docAssocs of
        Nothing -> strip isSpace x'' ++ " not available"
        Just (x, m)  -> begin
               </> P.unpack m
               </> map (choice (=='.') (const sep) id) (P.unpack x)
               <.> end
    where 
        choice p f g = p >>= \b -> if b then f else g
        x'  = map toLower (strip isSpace x'')
