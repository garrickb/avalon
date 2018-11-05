module Data.Session exposing (Session, initialSession)


type alias Session =
    { userName : Maybe String
    , lobbyName : Maybe String
    }


initialSession : Session
initialSession =
    { userName = Nothing, lobbyName = Nothing }
