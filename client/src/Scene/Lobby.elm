module Scene.Lobby exposing (Model, Msg, init, subscription, update, view)

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
import Bootstrap.Popover as Popover
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Data.Game exposing (..)
import Data.LobbyChannel as LobbyChannel exposing (LobbyState(..), lobbyChannel)
import Data.Session exposing (Session)
import Data.Socket exposing (SocketState(..), socketUrl)
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
import Phoenix.Socket as Socket exposing (Socket)
import Route
import Scene.Game


-- MODEL --


type alias Model =
    { socketState : SocketState
    , lobbyState : LobbyState
    , presence : Dict String (List JD.Value)
    , settingsVisibility : Modal.Visibility
    }


init : Model
init =
    { socketState = SocketClosed
    , lobbyState = LeftLobby
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
        lobbyName =
            Maybe.withDefault "" session.lobbyName

        userName =
            Maybe.withDefault "" session.userName
    in
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h1 [ style [ ( "text-align", "center" ) ] ] [ text lobbyName ]
            , Card.config [ Card.align Text.alignXsCenter ]
                |> Card.block []
                    [ Block.text []
                        [ viewPlayers userName model.presence
                        , Html.hr [] []
                        , div [ class "text-center" ]
                            [ Button.button
                                [ Button.outlineSecondary
                                , Button.attrs [ Spacing.ml1, onClick <| SettingsModal Modal.shown ]
                                ]
                                [ span [ class "fa fa-cog" ] [] ]
                            , Button.button
                                [ Button.primary
                                , Button.attrs [ Spacing.ml1, onClick StartGame ]
                                ]
                                [ text "Start Game", span [ class "oi oi-cog" ] [] ]
                            ]
                        ]
                    ]
                |> Card.view
            , viewSettings model.settingsVisibility
            ]
        ]


view : Session -> Model -> Html Msg
view session model =
    case model.lobbyState of
        JoinedLobby (Just game) ->
            Html.map GameMsg <| Scene.Game.view session game

        _ ->
            viewLobby session model



-- SUBSCRIPTION --


initSocket : Session -> String -> Socket Msg
initSocket session socketUrl =
    let
        params =
            case session.userName of
                Just user ->
                    [ ( "username", user ) ]

                Nothing ->
                    []
    in
    Socket.init socketUrl
        |> Socket.withParams params
        |> Socket.onOpen (SetSocketState SocketOpened)
        |> Socket.onClose (\_ -> GoToHomePage)
        |> Socket.onAbnormalClose (\_ -> GoToHomePage)
        |> Socket.reconnectTimer (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)
        |> Socket.withDebug


getChannel : Session -> Channel Msg
getChannel session =
    let
        params =
            case session.userName of
                Just user ->
                    [ ( "username", JE.string user ) ]

                Nothing ->
                    -- TODO: redirect to home
                    []

        lobbyRoute =
            case session.lobbyName of
                -- TODO: redirect to home
                Nothing ->
                    ""

                Just lobby ->
                    lobbyChannel lobby

        presence =
            Presence.create
                |> Presence.onChange UpdatePresence
    in
    Channel.init lobbyRoute
        |> Channel.withPayload (JE.object params)
        |> Channel.onRequestJoin LobbyJoining
        |> Channel.onJoin (\msg -> LobbyJoined msg)
        |> Channel.onLeave (\_ -> GoToHomePage)
        |> Channel.onJoinError (\_ -> GoToHomePage)
        |> Channel.on "game:state" (\msg -> NewGameState (Just msg))
        |> Channel.on "game:stop" (\msg -> NewGameState Nothing)
        |> Channel.withPresence presence
        |> Channel.withDebug


subscription : Session -> Sub Msg
subscription session =
    let
        phoenixSubscriptions =
            case session.userName of
                Nothing ->
                    [ Phoenix.connect (initSocket session socketUrl) [] ]

                Just lobby ->
                    [ Phoenix.connect (initSocket session socketUrl) [ getChannel session ] ]
    in
    Sub.batch phoenixSubscriptions



-- UPDATE --


type Msg
    = GoToHomePage
    | SetSocketState SocketState
    | LobbyJoining
    | LobbyJoined JD.Value
    | UpdatePresence (Dict String (List JD.Value))
    | SettingsModal Modal.Visibility
    | StartGame
    | NewGameState (Maybe JD.Value)
    | GameMsg Scene.Game.Msg


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        GoToHomePage ->
            model ! [ Route.modifyUrl Route.Home ]

        SetSocketState newSocketState ->
            { model | socketState = newSocketState } ! []

        LobbyJoining ->
            { model | lobbyState = JoiningLobby } ! []

        LobbyJoined game ->
            { model | lobbyState = JoinedLobby Nothing }
                |> update session (NewGameState (Just game))

        UpdatePresence presenceState ->
            { model | presence = Debug.log "presenceState " presenceState }
                ! []

        SettingsModal visibility ->
            { model | settingsVisibility = visibility } ! []

        NewGameState game_state ->
            let
                log =
                    Debug.log "NewGameState: " game_state
            in
            case game_state of
                Nothing ->
                    { model | lobbyState = JoinedLobby Nothing } ! []

                Just payload ->
                    case Debug.log "LOBBYSTATE: " model.lobbyState of
                        JoinedLobby _ ->
                            case JD.decodeValue decodeGame payload of
                                Ok game ->
                                    { model | lobbyState = JoinedLobby (Just (Debug.log "new game state" game)) } ! []

                                Err err ->
                                    let
                                        log =
                                            Debug.log "Error decoding state: " err
                                    in
                                    model ! []

                        _ ->
                            model ! []

        StartGame ->
            case session.lobbyName of
                Nothing ->
                    model ! []

                Just lobby ->
                    let
                        push =
                            Push.init (lobbyChannel lobby) "game:start"
                    in
                    model ! [ Phoenix.push socketUrl push ]

        GameMsg msg ->
            case model.lobbyState of
                JoinedLobby (Just game_state) ->
                    let
                        ( stateModel, cmd ) =
                            Scene.Game.update session msg game_state
                    in
                    ( { model | lobbyState = JoinedLobby (Just stateModel) }, Cmd.map GameMsg cmd )

                _ ->
                    model ! []
