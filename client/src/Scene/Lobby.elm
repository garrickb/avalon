module Scene.Lobby exposing (ExternalMsg(..), Model, Msg, getChannel, init, update, view)

import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Modal as Modal
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Data.Game exposing (..)
import Data.RoomChannel as RoomChannel exposing (RoomState(..), roomChannelName)
import Data.Session exposing (Session, SessionMessage(..))
import Data.Socket exposing (socketUrl)
import Debug exposing (log)
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, h2, img, input, li, span, table, tbody, td, text, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Presence as Presence exposing (Presence)
import Phoenix.Push as Push
import Route
import Scene.Game


-- MODEL --


type alias Model =
    { name : String
    , roomState : RoomState
    , presence : Dict String (List JD.Value)
    , settingsVisibility : Modal.Visibility
    }


init : String -> Model
init name =
    { name = name
    , roomState = JoiningRoom
    , presence = Dict.empty
    , settingsVisibility = Modal.hidden
    }


characters : List String
characters =
    [ "Merlin", "Assassin", "Percival", "Mordred", "Oberon", "Morgana" ]



-- VIEW --


viewSetting : String -> Html Msg
viewSetting name =
    div []
        [ Checkbox.checkbox [ Checkbox.id name ] name ]


viewSettings : Modal.Visibility -> Html Msg
viewSettings visibility =
    Modal.config (SettingsModal Modal.hidden)
        |> Modal.small
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text "Game Settings" ]
        |> Modal.body []
            [ Form.form
                []
                (List.map viewSetting characters)
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick <| SettingsModal Modal.hidden ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view visibility


viewPlayer : String -> ( String, List JD.Value ) -> Grid.Column Msg
viewPlayer playerName ( name, values ) =
    let
        sizeAttrs =
            [ Col.md4, Col.sm6, Col.xs12, Col.attrs [ style [ ( "padding-bottom", "5px" ) ] ] ]
    in
    if name == playerName then
        Grid.col sizeAttrs [ text name, Badge.pillPrimary [ Spacing.ml1 ] [ text "you" ] ]
    else
        Grid.col sizeAttrs [ text name ]


viewPlayers : String -> Dict String (List JD.Value) -> Html Msg
viewPlayers playerName presence =
    let
        players =
            List.map (viewPlayer playerName) (Dict.toList presence)
    in
    Grid.container []
        [ Grid.row [ Row.centerXs ]
            players
        ]


viewLobby : Session -> Model -> Html Msg
viewLobby session model =
    let
        userName =
            Maybe.withDefault "" session.userName

        players =
            if model.roomState == JoiningRoom then
                viewPlayers userName (Dict.fromList [ ( userName, [] ) ])
            else
                viewPlayers userName model.presence
    in
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h1 [ style [ ( "text-align", "center" ) ] ] [ text model.name ]
            , Card.config [ Card.align Text.alignXsCenter ]
                |> Card.block []
                    [ Block.text []
                        [ players
                        , Html.hr [] []
                        , Grid.container []
                            [ Grid.row
                                []
                                [ Grid.col [ Col.xs4 ]
                                    [ Button.button
                                        [ Button.outlineDanger
                                        , Button.attrs [ Spacing.ml1, onClick (GoToHomePageWithMessage EmptyMsg) ]
                                        ]
                                        [ text "Leave" ]
                                    ]
                                , Grid.col [ Col.xs4 ]
                                    [ Button.button
                                        [ Button.outlineSecondary
                                        , Button.attrs [ Spacing.ml1, onClick <| SettingsModal Modal.shown ]
                                        ]
                                        [ span [ class "fa fa-cog" ] [] ]
                                    ]
                                , Grid.col [ Col.xs4 ]
                                    [ Button.button
                                        [ Button.outlinePrimary
                                        , Button.attrs [ Spacing.ml1, onClick StartGame ]
                                        ]
                                        [ text "Start" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                |> Card.view
            , viewSettings model.settingsVisibility
            ]
        ]


view : Session -> Model -> Html Msg
view session model =
    case model.roomState of
        JoinedRoom (Just room) ->
            case room.game of
                Nothing ->
                    text "no game?"

                Just game ->
                    Html.map GameMsg <| Scene.Game.view session game

        _ ->
            viewLobby session model



-- SUBSCRIPTION --


getChannel : Session -> String -> Channel Msg
getChannel session name =
    let
        params =
            case session.userName of
                Just user ->
                    [ ( "username", JE.string user ) ]

                Nothing ->
                    []

        lobbyRoute =
            roomChannelName name

        presence =
            Presence.create
                |> Presence.onChange UpdatePresence
    in
    Channel.init lobbyRoute
        |> Channel.withPayload (JE.object params)
        |> Channel.onRequestJoin RoomJoining
        |> Channel.onJoin (\msg -> RoomJoined msg)
        --|> Channel.onLeave (\msg -> GoToHomePageWithMessage (InfoMsg (toString msg)))
        |> Channel.onJoinError (\msg -> GoToHomePageWithMessage (ErrorMsg (toString msg)))
        |> Channel.on "game:state" (\msg -> NewGameState (Just msg))
        |> Channel.on "game:stop" (\msg -> NewGameState Nothing)
        |> Channel.withPresence presence
        |> Channel.withDebug



-- UPDATE --


type ExternalMsg
    = NoOp
    | SetMessage SessionMessage


type Msg
    = GoToHomePageWithMessage SessionMessage
    | RoomJoining
    | RoomJoined JD.Value
    | UpdatePresence (Dict String (List JD.Value))
    | SettingsModal Modal.Visibility
    | StartGame
    | NewGameState (Maybe JD.Value)
    | GameMsg Scene.Game.Msg


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    case msg of
        GoToHomePageWithMessage msg ->
            ( model ! [ Route.modifyUrl Route.Home ], SetMessage msg )

        RoomJoining ->
            ( { model | roomState = JoiningRoom } ! [], NoOp )

        RoomJoined room ->
            let
                ( ( mdl, msg ), exMsg ) =
                    update session (NewGameState (Just room)) model
            in
            ( { mdl | roomState = JoinedRoom Nothing } ! [ msg ], exMsg )

        UpdatePresence presenceState ->
            ( { model | presence = Debug.log "presenceState " presenceState }
                ! []
            , NoOp
            )

        SettingsModal visibility ->
            ( { model | settingsVisibility = visibility } ! [], NoOp )

        NewGameState game_state ->
            let
                log =
                    Debug.log "NewGameState: " game_state
            in
            case game_state of
                Nothing ->
                    ( { model | roomState = JoinedRoom Nothing } ! [], NoOp )

                Just payload ->
                    case Debug.log "ROOMSTATE: " model.roomState of
                        JoinedRoom _ ->
                            case JD.decodeValue decodeRoom payload of
                                Ok game ->
                                    ( { model | roomState = JoinedRoom (Just (Debug.log "new game state" game)) } ! [], NoOp )

                                Err err ->
                                    let
                                        log =
                                            Debug.log "Error decoding state: " err
                                    in
                                    ( model ! [], NoOp )

                        _ ->
                            ( model ! [], NoOp )

        StartGame ->
            let
                push =
                    Push.init (roomChannelName model.name) "game:start"
            in
            ( model ! [ Phoenix.push socketUrl push ], NoOp )

        GameMsg msg ->
            case model.roomState of
                JoinedRoom (Just roomState) ->
                    case roomState.game of
                        Nothing ->
                            ( model ! [], NoOp )

                        Just game ->
                            let
                                ( newGame, cmd ) =
                                    Scene.Game.update model.name session msg game

                                newState =
                                    { roomState | game = Just newGame }
                            in
                            ( ( { model | roomState = JoinedRoom (Just newState) }, Cmd.map GameMsg cmd ), NoOp )

                _ ->
                    ( model ! [], NoOp )
