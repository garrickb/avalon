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
    , roomName : String
    , state : HomePageState
    }


type HomePageState
    = JoinRoomPage
    | CreateRoomPage


init : Session -> Model
init session =
    let
        userName =
            Maybe.withDefault "" session.userName
    in
    { userName = userName, roomName = "", state = JoinRoomPage }



-- VIEW --


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


view : Session -> Model -> Html Msg
view session model =
    let
        content =
            case model.state of
                JoinRoomPage ->
                    [ Form.group []
                        [ Form.label [] [ text "Username" ]
                        , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
                        ]
                    , Form.group []
                        [ Form.label [] [ text "Room Name" ]
                        , Input.text [ Input.attrs [ value model.roomName, onInput InputRoomName, onKeyDown RoomNameKeyDown, placeholder "Room Name" ] ]
                        ]
                    , div [ class "text-center" ]
                        [ Button.button [ Button.primary, Button.attrs [ onClick JoinRoom ] ] [ text "Join Room" ]
                        , Button.button [ Button.roleLink, Button.attrs [ onClick (SetPageState CreateRoomPage) ] ] [ text "Create Room" ]
                        ]
                    ]

                CreateRoomPage ->
                    [ Form.group []
                        [ Form.label [] [ text "Username" ]
                        , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
                        ]
                    , div [ class "text-center" ]
                        [ Button.button [ Button.roleLink, Button.attrs [ onClick (SetPageState JoinRoomPage) ] ] [ text "Back" ]
                        , Button.button [ Button.primary, Button.attrs [ onClick CreateRoom ] ] [ text "Create Room" ]
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


decodeCreatedRoomName : JD.Decoder String
decodeCreatedRoomName =
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
    = InputRoomName String
    | InputUserName String
    | RoomNameKeyDown Int
    | JoinRoom
    | CreateRoom
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

        InputRoomName name ->
            ( ( { model | roomName = name }, Cmd.none ), NoOp )

        InputUserName name ->
            ( ( { model | userName = name }, Cmd.none ), SetSessionInfo (Just name) )

        RoomNameKeyDown key ->
            if key == 13 then
                update JoinRoom model
            else
                ( ( model, Cmd.none ), NoOp )

        JoinRoom ->
            let
                roomName =
                    String.trim model.roomName

                userName =
                    String.trim model.userName
            in
            if (String.length roomName > 0) && (String.length userName > 0) then
                ( ( model, Cmd.batch [ Route.modifyUrl (Route.Room roomName) ] )
                , SetMessage EmptyMsg
                )
            else
                ( ( model, Cmd.none ), SetMessage (InfoMsg "Invalid username or room name.") )

        CreateRoom ->
            ( model ! [ createRoomPush model ], NoOp )

        RoomCreated payload ->
            case JD.decodeValue decodeCreatedRoomName payload of
                Ok roomName ->
                    ( ( model, Cmd.batch [ Route.modifyUrl (Route.Room roomName) ] )
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
