module Data.Lobby exposing (Lobby)

import Data.Player exposing (Player)
import Phoenix.Socket as Socket


type alias Lobby =
    { name : String
    , socket : Maybe (Socket.Socket Socket.Msg)
    }
