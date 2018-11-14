module Data.Session exposing (Session, SessionMessage(..), initialSession)


type alias Session =
    { userName : Maybe String
    }


type SessionMessage
    = EmptyMsg
    | InfoMsg String
    | ErrorMsg String


initialSession : Session
initialSession =
    { userName = Nothing }
