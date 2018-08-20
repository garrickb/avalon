module Page.Home.Function exposing (init, initWithName)

import Model.Dummy exposing (Dummy)
import Page.Home.Model exposing (Model)


init : Model
init =
    { username = ""
    , lobbyname = ""
    }


initWithName : String -> Model
initWithName defaultName =
    { username = defaultName
    , lobbyname = ""
    }
