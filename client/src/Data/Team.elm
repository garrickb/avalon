module Data.Team exposing (..)

import Json.Decode exposing (..)


type alias Team =
    { players : List String
    , num_players_required : Int
    , votes : List ( String, String )
    }


decodeTeam : Decoder Team
decodeTeam =
    map3 Team
        (field "players" (list string))
        (field "num_players_required" int)
        (field "votes"
            (keyValuePairs string)
        )
