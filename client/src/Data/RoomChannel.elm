module Data.RoomChannel exposing (RoomState(..), roomChannelName)

import Data.Room exposing (Room)


roomChannelName : String -> String
roomChannelName lobbyName =
    "room:" ++ lobbyName


type RoomState
    = JoiningRoom
    | JoinedRoom (Maybe Room)
    | LeftRoom
