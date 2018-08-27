module Data.Session exposing (Session, initialSession)

import Data.Room exposing (Room)
import Data.User exposing (User)


type alias Session =
    { user : Maybe User
    , room : Maybe Room
    }


initialSession : Session
initialSession =
    { user = Nothing, room = Nothing }
