module Data.Channel exposing (ChannelState(..), lobbyChannel)

import Data.Lobby exposing (Lobby)


lobbyChannel : Lobby -> String
lobbyChannel lobby =
    "lobby:" ++ lobby.name


type ChannelState
    = JoiningChannel
    | JoinedChannel
    | LeftChannel
