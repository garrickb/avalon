module Scene.Game exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Data.Game exposing (Game, Player, Quest)
import Data.LobbyChannel as LobbyChannel exposing (LobbyState(..), lobbyChannel)
import Data.Session exposing (Session)
import Data.Socket exposing (SocketState(..), socketUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Phoenix
import Phoenix.Push as Push
import Scene.Game.Player as Player
import Scene.Game.Quest as Quest
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
                        "Waiting..."
                    else
                        "Ready"
            in
            div []
                [ p [] [ text ("You are: " ++ self.role) ]
                , Button.button [ Button.primary, Button.attrs [ onClick PlayerReady ], Button.disabled self.ready ] [ text buttonText ]
                ]

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


viewBoard : Game -> Html Msg
viewBoard game =
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ), ( "text-align", "center" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h1 [] [ text game.name ]
            , Card.config []
                |> Card.block []
                    [ Block.text []
                        [ Quest.viewQuests game.quests
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
        , Player.viewPlayers game.players username game.fsm.state
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
