module Data.RoomChannel exposing (RoomState(..), roomChannelName)

import Data.Game exposing (..)


roomChannelName : String -> String
roomChannelName lobbyName =
    "room:" ++ lobbyName


type RoomState
    = JoiningRoom
    | JoinedRoom (Maybe Room)
    | LeftRoom
