module Scene.Lobby exposing (Model, Msg, init, subscription, update, view)

import Data.LobbyName as LobbyName
import Data.Session exposing (Session, getLobbyName)
import Html exposing (Html, button, div, h1, h2, input, li, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Phoenix
import Phoenix.Socket as Socket exposing (Socket)


-- MODEL --


type alias ChatModel =
    { messages : List String
    , chatInput : String
    }


type alias Model =
    { session : Session
    , chat : ChatModel
    }


init : Session -> Model
init session =
    { session = session
    , chat =
        { messages = [ "welcome to da lobby my man" ]
        , chatInput = ""
        }
    }



-- VIEW --


viewMessages : List String -> Html Msg
viewMessages messages =
    messages
        |> List.map (\message -> li [] [ text message ])
        |> ul []


viewChatBox : String -> Html Msg
viewChatBox currentValue =
    div []
        [ input [ placeholder "Message", onInput MessageInput, value currentValue ] []
        , button [ onClick SubmitMessage ] [ text "Submit" ]
        ]


viewChat : ChatModel -> Html Msg
viewChat chatModel =
    div []
        [ text "this is the chat"
        , viewMessages chatModel.messages
        , viewChatBox chatModel.chatInput
        ]


view : Session -> Model -> Html Msg
view session model =
    case session.lobby of
        Nothing ->
            div []
                [ h2 [] [ text "you should probably go to the home page and join a lobby, my main man." ] ]

        Just lobby ->
            div []
                [ h1 [] [ text (getLobbyName session) ]
                , viewChat model.chat
                ]



-- SUBSCRIPTION --


socketUrl : String
socketUrl =
    "room:lobby"


initSocket : Session -> String -> Socket Msg
initSocket session socketUrl =
    let
        params =
            case session.user of
                Just user ->
                    [ ( "username", user.username ) ]

                Nothing ->
                    []
    in
    Socket.init socketUrl
        |> Socket.withParams params
        |> Socket.onOpen SocketOpened
        |> Socket.onClose (\_ -> SocketClosed)
        |> Socket.onAbnormalClose (\_ -> SocketClosedAbnormally)


subscription : Session -> Sub Msg
subscription session =
    let
        phoenixSubscriptions =
            [ Phoenix.connect (initSocket session socketUrl) [] ]

        -- more subscriptions unrelated to the socket connection setup here
    in
    Sub.batch phoenixSubscriptions



-- UPDATE --


type Msg
    = MessageInput String
    | SubmitMessage
    | SocketOpened
    | SocketClosed
    | SocketClosedAbnormally


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageInput input ->
            let
                newChat =
                    { chatInput = input, messages = model.chat.messages }
            in
            ( { model | chat = newChat }, Cmd.none )

        SubmitMessage ->
            let
                newMessages =
                    model.chat.messages ++ [ model.chat.chatInput ]

                newChat =
                    { chatInput = "", messages = newMessages }
            in
            ( { model | chat = newChat }, Cmd.none )

        SocketOpened ->
            -- TODO
            let
                newMessages =
                    model.chat.messages ++ [ "Socket Opened" ]

                newChat =
                    { chatInput = "", messages = newMessages }
            in
            ( { model | chat = newChat }, Cmd.none )

        SocketClosed ->
            -- TODO
            let
                newMessages =
                    model.chat.messages ++ [ "Socket Closed" ]

                newChat =
                    { chatInput = "", messages = newMessages }
            in
            ( { model | chat = newChat }, Cmd.none )

        SocketClosedAbnormally ->
            -- TODO
            let
                newMessages =
                    model.chat.messages ++ [ "Socket Closed Abnormally" ]

                newChat =
                    { chatInput = "", messages = newMessages }
            in
            ( { model | chat = newChat }, Cmd.none )
