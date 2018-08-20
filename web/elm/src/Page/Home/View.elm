module Page.Home.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page.Home.Message exposing (..)
import Page.Home.Model exposing (Model)


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Lobby" ]
        , div []
            [ input [ placeholder "Name", onInput UserName, defaultValue model.username ] []
            , input [ placeholder "Lobby name", onInput LobbyName ] []
            , button [ onClick JoinLobby ] [ text "Join" ]
            ]
        ]
