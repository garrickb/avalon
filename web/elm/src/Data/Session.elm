module Data.Session exposing (Session, initialSession)

import Data.Lobby exposing (Lobby)
import Data.User exposing (User)


type alias Session =
    { user : Maybe User
    , lobby : Maybe Lobby
    }


initialSession : Session
initialSession =
    { user = Nothing, lobby = Nothing }
