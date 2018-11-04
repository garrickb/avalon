module Data.RoomChannel exposing (RoomState(..), roomChannel)

import Data.Room exposing (..)


roomChannel : String -> String
roomChannel roomName =
    "room:" ++ roomName


type RoomState
    = JoiningRoom
    | JoinedRoom (Maybe Room)
    | LeftRoom
