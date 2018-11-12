module Data.LobbyChannel exposing (LobbyState(..), roomChannelName)

import Data.Game exposing (..)


roomChannelName : String -> String
roomChannelName lobbyName =
    "room:" ++ lobbyName


type LobbyState
    = JoiningLobby
    | JoinedLobby (Maybe Game)
    | LeftLobby
