module Data.Room exposing (Room, decodeGameState, initialRoom)

import Json.Decode as JD exposing (Decoder)


type alias Room =
    { name : String
    , players : List String
    }


initialRoom : Room
initialRoom =
    { name = "default room name"
    , players = []
    }


decodeGameState : Decoder Room
decodeGameState =
    JD.map2 (\name players -> { name = name, players = players })
        (JD.field "name" JD.string)
        (JD.field "players" (JD.list JD.string))
