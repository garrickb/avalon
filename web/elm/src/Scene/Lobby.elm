module Scene.Lobby exposing (Model, Msg, init, subscription, update, view)

import Data.Channel exposing (ChannelState(..), lobbyChannel)
import Data.ChatMessage exposing (ChatMsg, decodeChatMsg)
import Data.Session exposing (Session, getLobbyName)
import Data.Socket exposing (SocketState(..), socketUrl)
import Html exposing (Html, button, div, h1, h2, img, input, li, span, table, tbody, td, text, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push
import Phoenix.Socket as Socket exposing (Socket)


-- MODEL --


type alias ChatModel =
    { messages : List ChatMsg
    , chatInput : String
    }


type alias Model =
    { chat : ChatModel
    , socketState : SocketState
    , channelState : ChannelState
    }


init : Model
init =
    { chat =
        { messages = []
        , chatInput = ""
        }
    , socketState = SocketClosed
    , channelState = LeftChannel
    }



-- VIEW --


viewMessages : List ChatMsg -> Html Msg
viewMessages messages =
    table [ class "table table-striped" ]
        [ tbody []
            (messages
                |> List.map
                    (\message ->
                        let
                            avatarUrl =
                                "https://api.adorable.io/avatars/40/" ++ message.userName ++ ".png"
                        in
                        tr []
                            [ td []
                                [ img [ src avatarUrl, style [ ( "margin_right", "20px" ) ] ] []
                                , text message.userName
                                , div [] [ text message.message ]
                                ]
                            ]
                    )
            )
        ]


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


viewChatBox : String -> Html Msg
viewChatBox currentValue =
    div []
        [ input [ placeholder "Message", onInput MessageInput, onKeyDown MessageKeyDown, value currentValue ] []
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
        |> Socket.onOpen (SetSocketState SocketOpened)
        |> Socket.onClose (\_ -> SetSocketState SocketClosed)
        |> Socket.onAbnormalClose (\_ -> SetSocketState SocketClosed)
        |> Socket.reconnectTimer (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)


getChannel : Session -> Channel Msg
getChannel session =
    let
        params =
            case session.user of
                Just user ->
                    [ ( "username", JE.string user.username ) ]

                Nothing ->
                    []

        lobbyRoute =
            case session.lobby of
                Nothing ->
                    "lobby:lobby"

                Just lobby ->
                    lobbyChannel lobby
    in
    Channel.init lobbyRoute
        |> Channel.withPayload (JE.object params)
        |> Channel.onRequestJoin (SetChannelState JoiningChannel)
        |> Channel.onJoin (\_ -> SetChannelState JoinedChannel)
        |> Channel.onLeave (\_ -> SetChannelState LeftChannel)
        |> Channel.on (lobbyRoute ++ ":shout") (\msg -> NewMsg msg)
        --|> Channel.withPresence presence
        |> Channel.withDebug


subscription : Session -> Sub Msg
subscription session =
    let
        phoenixSubscriptions =
            case session.user of
                Nothing ->
                    [ Phoenix.connect (initSocket session socketUrl) [] ]

                Just lobby ->
                    [ Phoenix.connect (initSocket session socketUrl) [ getChannel session ] ]
    in
    Sub.batch phoenixSubscriptions



-- UPDATE --


type Msg
    = MessageInput String
    | MessageKeyDown Int
    | SubmitMessage
    | SetSocketState SocketState
    | SetChannelState ChannelState
    | NewMsg JD.Value



--| SetChannel (Channel Msg)


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        MessageInput input ->
            let
                newChat =
                    { chatInput = input, messages = model.chat.messages }
            in
            { model | chat = newChat } ! []

        MessageKeyDown key ->
            if key == 13 then
                update session SubmitMessage model
            else
                model ! []

        SubmitMessage ->
            case session.lobby of
                Nothing ->
                    model ! []

                Just lobby ->
                    if String.length model.chat.chatInput == 0 then
                        model ! []
                    else
                        let
                            newChat =
                                { chatInput = "", messages = model.chat.messages }

                            push =
                                Push.init (lobbyChannel lobby) "shout"
                                    |> Push.withPayload (JE.object [ ( "msg", JE.string model.chat.chatInput ) ])
                        in
                        { model | chat = newChat } ! [ Phoenix.push socketUrl push ]

        SetSocketState newSocketState ->
            { model | socketState = newSocketState } ! []

        SetChannelState newChannelState ->
            { model | channelState = newChannelState } ! []

        NewMsg payload ->
            case JD.decodeValue decodeChatMsg payload of
                Ok msg ->
                    let
                        newMessages =
                            model.chat.messages ++ [ msg ]

                        newChat =
                            { chatInput = model.chat.chatInput, messages = newMessages }
                    in
                    { model | chat = newChat } ! [ Cmd.none ]

                Err err ->
                    model ! []
