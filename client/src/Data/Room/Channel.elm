module Data.Room.Channel exposing (RoomState(..), roomChannel)

import Data.Room exposing (Room)


roomChannel : Room -> String
roomChannel room =
    "room:" ++ room.name


type RoomState
    = JoiningRoom
    | JoinedRoom
    | LeftRoom
