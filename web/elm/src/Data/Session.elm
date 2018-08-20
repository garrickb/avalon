module Data.Session exposing (Session, initialSession)

import Data.Lobby exposing (Lobby)
import Data.Player exposing (Player)


type alias Session =
    { player : Maybe Player
    , lobby : Maybe Lobby
    }


initialSession : Session
initialSession =
    { player = Nothing, lobby = Nothing }
