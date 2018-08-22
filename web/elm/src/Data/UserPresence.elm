module Data.UserPresence exposing (Model, init)


type alias Model =
    { online_at : String
    , device : String
    }


init : Model
init =
    { online_at = ""
    , device = ""
    }
