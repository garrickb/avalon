module Data.Player exposing (Player, defaultPlayer)


type alias Player =
    { username : String }


type alias PlayerPresence =
    { online_at : String
    , device : String
    }



-- Initialization --


defaultPlayer : Player
defaultPlayer =
    { username = "" }
