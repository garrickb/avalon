module Scene.Game exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Data.Game exposing (Game)
import Data.LobbyChannel as LobbyChannel exposing (LobbyState(..), lobbyChannel)
import Data.Session exposing (Session)
import Data.Socket exposing (SocketState(..), socketUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Phoenix
import Phoenix.Push as Push
import Svg
import Svg.Attributes as SvgAttr


-- VIEW --


viewDebug : Game -> Html msg
viewDebug game =
    Card.config []
        |> Card.block []
            [ Block.text []
                [ h5 [] [ text game.player.name ]
                , hr [] []
                , p [] [ text ("BY GAHD, YOU'RE " ++ game.player.role) ]
                ]
            ]
        |> Card.view


viewDrawer : Game -> Html Msg
viewDrawer game =
    Grid.row
        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "bottom", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
        [ Grid.col []
            [ viewDebug game ]
        ]


viewQuest : Int -> Html msg
viewQuest numPlayers =
    let
        size =
            50

        sizeStr =
            toString size

        halfSizeStr =
            toString (size / 2)
    in
    span [ style [ ( "padding", "1px" ) ] ]
        [ Svg.svg
            [ SvgAttr.width sizeStr
            , SvgAttr.height sizeStr
            ]
            [ Svg.circle
                [ SvgAttr.cx halfSizeStr
                , SvgAttr.cy halfSizeStr
                , SvgAttr.r halfSizeStr
                ]
                []
            , Svg.text_
                [ SvgAttr.x "16"
                , SvgAttr.y "34"
                , SvgAttr.fontSize "30"
                , SvgAttr.fill "white"
                ]
                [ Svg.text (toString numPlayers) ]
            ]
        ]


viewQuests : Html Msg
viewQuests =
    let
        quests =
            [ 1, 2, 3, 4, 5 ]
    in
    div []
        (List.map
            viewQuest
            quests
        )


viewPlayer : String -> Grid.Column Msg
viewPlayer name =
    Grid.col []
        [ Card.config []
            |> Card.block []
                [ Block.text []
                    [ text name ]
                ]
            |> Card.view
        ]


viewPlayers : String -> List String -> Html Msg
viewPlayers ignorePlayer players =
    Grid.row
        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
        (List.filter (\x -> x /= ignorePlayer) players
            |> List.map viewPlayer
        )


viewBoard : Game -> Html Msg
viewBoard game =
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ), ( "text-align", "center" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h1 [] [ text game.name ]
            , Card.config []
                |> Card.block []
                    [ Block.text []
                        [ viewQuests
                        ]
                    ]
                |> Card.view
            , div [ style [ ( "padding-top", "2%" ) ] ]
                [ Button.button [ Button.primary, Button.attrs [ onClick StopGame ] ] [ text "Stop Game" ] ]
            ]
        ]


view : Session -> Game -> Html Msg
view session model =
    div []
        [ viewBoard model
        , viewPlayers model.player.name model.players
        , viewDrawer model
        ]


type Msg
    = StopGame


update : Session -> Msg -> Game -> ( Game, Cmd Msg )
update session msg model =
    case msg of
        StopGame ->
            case session.lobbyName of
                Nothing ->
                    model ! []

                Just lobby ->
                    let
                        push =
                            Push.init (lobbyChannel lobby) "game:stop"
                    in
                    model ! [ Phoenix.push socketUrl push ]
