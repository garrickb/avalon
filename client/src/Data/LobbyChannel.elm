module Data.LobbyChannel exposing (LobbyState(..), lobbyChannel)

import Data.Game exposing (..)


lobbyChannel : String -> String
lobbyChannel lobbyName =
    "room:" ++ lobbyName


type LobbyState
    = JoiningLobby
    | JoinedLobby (Maybe Game)
    | LeftLobby
