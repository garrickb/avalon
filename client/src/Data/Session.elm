module Data.Session exposing (Session, initialSession)


type alias Session =
    { userName : Maybe String
    , roomName : Maybe String
    }


initialSession : Session
initialSession =
    { userName = Nothing, roomName = Nothing }
