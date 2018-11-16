module Data.Settings exposing (..)

import Json.Decode exposing (..)


type alias Settings =
    { merlin : Bool
    , assassin : Bool
    , percival : Bool
    , mordred : Bool
    , oberon : Bool
    , morgana : Bool
    }


decodeSettings : Decoder Settings
decodeSettings =
    map6 Settings
        (field "merlin" bool)
        (field "assassin" bool)
        (field "percival" bool)
        (field "mordred" bool)
        (field "oberon" bool)
        (field "morgana" bool)
