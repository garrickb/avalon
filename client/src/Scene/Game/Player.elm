module Scene.Game.Player exposing (..)

import Data.Game exposing (Player)
import Html exposing (..)
import Html.Attributes exposing (..)


type Modifier
    = Ready Bool
    | King


viewModifier : Modifier -> Html msg
viewModifier mod =
    let
        classes =
            "fa fa-small "
    in
    case mod of
        King ->
            span [ class (classes ++ "fa-crown"), style [ ( "color", "gold" ), ( "-webkit-text-stroke", "1px #000 " ) ] ] []

        Ready True ->
            span [ class (classes ++ "fa-check-circle"), style [ ( "color", "green" ) ] ] []

        Ready False ->
            span [ class (classes ++ "fa-times-circle"), style [ ( "color", "red" ) ] ] []


viewName : Player -> String -> Html msg
viewName player state =
    case state of
        "waiting" ->
            span [] [ text (player.name ++ " "), viewModifier (Ready player.ready) ]

        _ ->
            if player.king then
                span [] [ viewModifier King, text (" " ++ player.name) ]
            else
                span [] [ text player.name ]
