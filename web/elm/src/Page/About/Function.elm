module Page.About.Function exposing (init)

import Model.Dummy exposing (Dummy)
import Page.About.Model exposing (Model)


init : Model
init =
    { pageTitle = "About"
    , pageBody = "This is the aboutpage"
    }
