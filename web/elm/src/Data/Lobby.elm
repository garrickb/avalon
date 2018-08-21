module Data.Lobby exposing (Lobby)

import Phoenix.Socket as Socket


type alias Lobby =
    { name : String
    , socket : Maybe (Socket.Socket Socket.Msg)
    }
