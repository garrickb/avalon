module Data.Session exposing (Session, getLobbyName, initialSession)

import Data.Lobby exposing (Lobby)
import Data.User exposing (User)


type alias Session =
    { user : Maybe User
    , lobby : Maybe Lobby
    }


initialSession : Session
initialSession =
    { user = Nothing, lobby = Nothing }


getLobbyName : Session -> String
getLobbyName session =
    case session.lobby of
        Nothing ->
            "Invalid Lobby"

        Just lobby ->
            lobby.name
