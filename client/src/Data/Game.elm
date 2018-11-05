module Data.Game exposing (Game, decodeGame, initialGame)

import Json.Decode as JD exposing (Decoder)


type alias Game =
    { name : String
    , players : List String
    }


type alias Player =
    { name : String }


initialGame : Game
initialGame =
    { name = ""
    , players = []
    }


decodeGame : Decoder Game
decodeGame =
    JD.map2 (\name players -> { name = name, players = players })
        (JD.field "name" JD.string)
        (JD.field "players" (JD.list JD.string))


decodePlayer : Decoder Player
decodePlayer =
    JD.map Player
        (JD.field "name" JD.string)
