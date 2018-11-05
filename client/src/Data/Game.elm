module Data.Game exposing (Game, decodeGameState, initialGame)

import Json.Decode as JD exposing (Decoder)


type alias Game =
    { name : String
    , players : List String
    }


initialGame : Game
initialGame =
    { name = ""
    , players = []
    }


decodeGameState : Decoder Game
decodeGameState =
    JD.map2 (\name players -> { name = name, players = players })
        (JD.field "name" JD.string)
        (JD.field "players" (JD.list JD.string))
