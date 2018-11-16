module Data.Room exposing (..)

import Data.Game exposing (..)
import Data.Settings exposing (..)
import Json.Decode exposing (..)


type alias Room =
    { id : String
    , settings : Settings
    , game : Maybe Game
    }


decodeRoom : Decoder Room
decodeRoom =
    map3 Room
        (field "id" string)
        (field "settings" decodeSettings)
        (field "game" (nullable decodeGame))
