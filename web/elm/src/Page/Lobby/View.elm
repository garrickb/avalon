module Page.Lobby.View exposing (view)

import Html exposing (..)
import Page.Lobby.Message exposing (..)
import Page.Lobby.Model exposing (Model)


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Lobby View" ]
        , div [] [ text "This is a lobby" ]
        ]
