module Scene.Game.Player exposing (..)

import Data.Game exposing (GameFsmState(..), Player, Quest)
import Html exposing (..)
import Html.Attributes exposing (..)


type Modifier
    = Ready Bool
    | King
    | OnQuest


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

        OnQuest ->
            span [ class (classes ++ "fa-shield-alt"), style [ ( "color", "#B8860B" ) ] ] []


viewName : Player -> GameFsmState -> Maybe Quest -> Html msg
viewName player state quest =
    let
        playerName =
            if player.king then
                span [] [ viewModifier King, text (" " ++ player.name) ]
            else
                text player.name
    in
    case state of
        Waiting ->
            span [] [ playerName, text " ", viewModifier (Ready player.ready) ]

        _ ->
            case quest of
                Nothing ->
                    playerName

                Just quest ->
                    if List.member player.name quest.team.players then
                        span [] [ playerName, text " ", viewModifier OnQuest ]
                    else
                        playerName
