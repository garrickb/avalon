module Scene.Game.Player exposing (..)

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Data.Game exposing (Player)
import Html exposing (..)
import Html.Attributes exposing (..)


type Modifier
    = Ready Bool
    | King


viewPlayer : String -> Player -> Grid.Column msg
viewPlayer state player =
    Grid.col []
        [ Card.config []
            |> Card.block []
                [ Block.text []
                    [ viewName player state ]
                ]
            |> Card.view
        ]


viewPlayers : List Player -> String -> String -> Html msg
viewPlayers players ignorePlayer state =
    Grid.row
        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
        (List.filter (\p -> p.name /= ignorePlayer) players
            |> List.map (viewPlayer state)
        )


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
