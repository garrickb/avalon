module Scene.Lobby exposing (Model, Msg(..), init, view)

import Data.Session exposing (Session)
import Html exposing (Html, text)


-- MODEL --


type alias Model =
    {}


init : Model
init =
    {}



-- VIEW --


view : Session -> Model -> Html Msg
view session model =
    text "hello lobby"



-- UPDATE --


type Msg
    = NoOp
    | DoThing
