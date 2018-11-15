module Scene.Home exposing (ExternalMsg(..), Model, Msg, getChannel, init, update, view)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Data.Session exposing (Session, SessionMessage(..))
import Data.Socket exposing (socketUrl)
import Debug exposing (log)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as JD
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push
import Route exposing (Route)


-- MODEL --


type alias Model =
    { userName : String
    , lobbyName : String
    , state : HomePageState
    }


type HomePageState
    = JoinLobbyPage
    | CreateLobbyPage


init : Session -> Model
init session =
    let
        userName =
            Maybe.withDefault "" session.userName
    in
    { userName = userName, lobbyName = "", state = JoinLobbyPage }



-- VIEW --


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


view : Session -> Model -> Html Msg
view session model =
    let
        content =
            case model.state of
                JoinLobbyPage ->
                    [ Form.group []
                        [ Form.label [] [ text "Username" ]
                        , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
                        ]
                    , Form.group []
                        [ Form.label [] [ text "Lobby Name" ]
                        , Input.text [ Input.attrs [ value model.lobbyName, onInput InputLobbyName, onKeyDown LobbyNameKeyDown, placeholder "Lobby Name" ] ]
                        ]
                    , div [ class "text-center" ]
                        [ Button.button [ Button.primary, Button.attrs [ onClick JoinLobby ] ] [ text "Join Lobby" ]
                        , Button.button [ Button.roleLink, Button.attrs [ onClick (SetPageState CreateLobbyPage) ] ] [ text "Create Lobby" ]
                        ]
                    ]

                CreateLobbyPage ->
                    [ Form.group []
                        [ Form.label [] [ text "Username" ]
                        , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
                        ]
                    , div [ class "text-center" ]
                        [ Button.button [ Button.roleLink, Button.attrs [ onClick (SetPageState JoinLobbyPage) ] ] [ text "Back" ]
                        , Button.button [ Button.primary, Button.attrs [ onClick CreateLobby ] ] [ text "Create Lobby" ]
                        ]
                    ]
    in
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h1 [ style [ ( "text-align", "center" ) ] ] [ text "Avalon" ]
            , Card.config []
                |> Card.block []
                    [ Block.text []
                        content
                    ]
                |> Card.view
            , div [ class "text-muted text-center font-weight-light", style [ ( "padding-top", "5%" ) ] ]
                [ text "Made with "
                , text "\x1F9D9"
                , text "by "
                , a [ href "https://github.com/garrickb" ] [ text "Garrick" ]
                ]
            ]
        ]



-- SUBSCRIPTION --


getChannel : Session -> Channel Msg
getChannel session =
    let
        a =
            Debug.log "get channel"
    in
    Channel.init "home"
        --|> Channel.onError (\msg -> SetMessage msg)
        |> Channel.onJoinError (\msg -> SetMessage2 (ErrorMsg (toString msg)))
        |> Channel.withDebug



-- UPDATE --


decodeCreatedLobbyName : JD.Decoder String
decodeCreatedLobbyName =
    JD.field "room_id" JD.string


createRoomPush : Model -> Cmd Msg
createRoomPush model =
    let
        playerName =
            model.userName
    in
    Push.init "home" "room:create"
        |> Push.onOk (\payload -> RoomCreated payload)
        |> Push.onError (\payload -> RoomCreateFailed payload)
        |> Phoenix.push socketUrl


type Msg
    = InputLobbyName String
    | InputUserName String
    | LobbyNameKeyDown Int
    | JoinLobby
    | CreateLobby
    | SetMessage2 SessionMessage
    | SetPageState HomePageState
    | RoomCreated JD.Value
    | RoomCreateFailed JD.Value


type ExternalMsg
    = NoOp
    | SetSessionInfo (Maybe String)
    | SetMessage SessionMessage


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SetPageState pageState ->
            ( { model | state = pageState } ! [], NoOp )

        SetMessage2 msg ->
            ( model ! [], SetMessage msg )

        InputLobbyName name ->
            ( ( { model | lobbyName = name }, Cmd.none ), NoOp )

        InputUserName name ->
            ( ( { model | userName = name }, Cmd.none ), SetSessionInfo (Just name) )

        LobbyNameKeyDown key ->
            if key == 13 then
                update JoinLobby model
            else
                ( ( model, Cmd.none ), NoOp )

        JoinLobby ->
            let
                lobbyName =
                    String.trim model.lobbyName

                userName =
                    String.trim model.userName
            in
            if (String.length lobbyName > 0) && (String.length userName > 0) then
                ( ( model, Cmd.batch [ Route.modifyUrl (Route.Lobby lobbyName) ] )
                , SetMessage EmptyMsg
                )
            else
                ( ( model, Cmd.none ), SetMessage (InfoMsg "Invalid username or room name.") )

        CreateLobby ->
            ( model ! [ createRoomPush model ], NoOp )

        RoomCreated payload ->
            case JD.decodeValue decodeCreatedLobbyName payload of
                Ok roomName ->
                    ( ( model, Cmd.batch [ Route.modifyUrl (Route.Lobby roomName) ] )
                    , SetMessage EmptyMsg
                    )

                Err err ->
                    let
                        log =
                            Debug.log "Error decoding state: " err
                    in
                    ( model ! [], SetMessage (ErrorMsg (toString payload)) )

        RoomCreateFailed payload ->
            ( model ! [], SetMessage (ErrorMsg (toString payload)) )
