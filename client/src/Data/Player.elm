module Data.Player exposing (Player, PlayerScene, decodePlayer, initPlayerScene)

import Data.Role exposing (..)
import Json.Decode exposing (..)


type alias Player =
    { name : String
    , role : Role
    , ready : Bool
    , king : Bool
    }


type alias PlayerScene =
    { hideInformation : Bool }


initPlayerScene : PlayerScene
initPlayerScene =
    { hideInformation = False }


decodePlayer : Decoder Player
decodePlayer =
    map4 Player
        (field "name" string)
        (field "role" decodeRole)
        (field "ready" bool)
        (field "king" bool)
