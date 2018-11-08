module Scene.Game exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Data.Game exposing (Game, Player)
import Data.LobbyChannel as LobbyChannel exposing (LobbyState(..), lobbyChannel)
import Data.Session exposing (Session)
import Data.Socket exposing (SocketState(..), socketUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Phoenix
import Phoenix.Push as Push
import Scene.Game.Player as Player
import Svg
import Svg.Attributes as SvgAttr


-- VIEW --


viewActions : Game -> Player -> Html Msg
viewActions game self =
    case game.fsm.state of
        "waiting" ->
            let
                buttonText =
                    if self.ready then
                        "Waiting"
                    else
                        "Ready"
            in
            Button.button [ Button.primary, Button.attrs [ onClick PlayerReady ], Button.disabled self.ready ] [ text buttonText ]

        "select_quest_members" ->
            if self.king then
                text "select your quest members"
            else
                text "waiting for quest members to be selected"

        _ ->
            text ("current state: " ++ game.fsm.state)


viewDrawer : Game -> Maybe Player -> Html Msg
viewDrawer game maybeSelf =
    let
        content =
            case maybeSelf of
                Just self ->
                    Card.config []
                        |> Card.block []
                            [ Block.text []
                                [ h5 [] [ Player.viewName self game.fsm.state ]
                                , hr [] []
                                , p [] []
                                , viewActions game self
                                ]
                            ]
                        |> Card.view

                Nothing ->
                    text "you are a spectator"
    in
    Grid.row
        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "bottom", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
        [ Grid.col []
            [ content ]
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


viewPlayer : String -> Player -> Grid.Column Msg
viewPlayer state player =
    Grid.col []
        [ Card.config []
            |> Card.block []
                [ Block.text []
                    [ Player.viewName player state ]
                ]
            |> Card.view
        ]


viewPlayers : List Player -> String -> String -> Html Msg
viewPlayers players ignorePlayer state =
    Grid.row
        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
        (List.filter (\p -> p.name /= ignorePlayer) players
            |> List.map (viewPlayer state)
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
                [ Button.button [ Button.outlineDanger, Button.attrs [ onClick StopGame ] ] [ text "Stop Game" ] ]
            ]
        ]


view : Session -> Game -> Html Msg
view session game =
    let
        username =
            Maybe.withDefault "" session.userName

        self =
            List.head <| List.filter (\p -> p.name == username) game.players
    in
    div []
        [ viewBoard game
        , viewPlayers game.players username game.fsm.state
        , viewDrawer game self
        ]


type Msg
    = StopGame
    | PlayerReady


pushMessage : String -> String -> Cmd msg
pushMessage lobby message =
    let
        push =
            Push.init (lobbyChannel lobby) message
    in
    Phoenix.push socketUrl push


update : Session -> Msg -> Game -> ( Game, Cmd Msg )
update session msg model =
    case session.lobbyName of
        Nothing ->
            model ! []

        Just lobby ->
            case msg of
                StopGame ->
                    model ! [ pushMessage lobby "game:stop" ]

                PlayerReady ->
                    model ! [ pushMessage lobby "player:ready" ]
