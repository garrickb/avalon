module Data.Msg exposing (Msg(..))

import Phoenix.Socket
import Route exposing (Route)
import Scene.Home as Home
import Scene.Lobby as Lobby


type Msg
    = SetRoute (Maybe Route)
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | LobbyMsg Lobby.Msg
    | HomeMsg Home.Msg
