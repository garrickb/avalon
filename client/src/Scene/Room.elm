module Scene.Room exposing (Model, Msg, init, subscription, update, view)

import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Utilities.Spacing as Spacing
import Data.ChatMessage exposing (ChatMessage(..), MessageModel, decodeChatMsg)
import Data.Room.Channel as RoomChannel exposing (RoomState(..), roomChannel)
import Data.Session exposing (Session)
import Data.Socket exposing (SocketState(..), socketUrl)
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


-- MODEL --


type alias Model =
    { chat : ChatModel
    , socketState : SocketState
    , roomState : RoomState
    , presence : Dict String (List JD.Value)
    }


type alias ChatModel =
    { messages : List ChatMessage
    , chatInput : String
    }


init : Model
init =
    { chat =
        { messages = []
        , chatInput = ""
        }
    , socketState = SocketClosed
    , roomState = LeftRoom
    , presence = Dict.empty
    }



-- VIEW --


viewMessage : String -> ChatMessage -> Html Msg
viewMessage name message =
    case message of
        SystemMessage message ->
            div []
                [ ListGroup.ul [ ListGroup.li [ ListGroup.info ] [ text message ] ] ]

        UserMessage username message ->
            if name == username then
                div []
                    [ div [] [ text username, Badge.pillPrimary [ Spacing.ml1 ] [ text "you" ] ]
                    , ListGroup.ul [ ListGroup.li [] [ text message ] ]
                    ]
            else
                div []
                    [ text username
                    , ListGroup.ul [ ListGroup.li [] [ text message ] ]
                    ]


viewMessages : String -> List ChatMessage -> Html Msg
viewMessages name messages =
    table [ class "table table-striped" ]
        [ tbody []
            (List.map
                (viewMessage name)
                messages
            )
        ]


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


viewChatBox : String -> Html Msg
viewChatBox currentValue =
    div []
        [ Form.group []
            [ Input.text [ Input.attrs [ onInput MessageInput, onKeyDown MessageKeyDown, value currentValue, placeholder "Message" ] ]
            , Button.button [ Button.primary, Button.block, Button.attrs [ onClick SubmitMessage ] ] [ text "Submit" ]
            ]
        ]


viewChat : String -> ChatModel -> Html Msg
viewChat name chatModel =
    Card.config []
        |> Card.header [] [ text "Chat" ]
        |> Card.block []
            [ Block.custom
                (div
                    []
                    [ viewMessages name chatModel.messages
                    , viewChatBox chatModel.chatInput
                    ]
                )
            ]
        |> Card.view


viewPlayer : String -> ( String, List JD.Value ) -> ListGroup.Item Msg
viewPlayer playerName ( name, values ) =
    if name == playerName then
        ListGroup.li [] [ text name, Badge.pillPrimary [ Spacing.ml1 ] [ text "you" ] ]
    else
        ListGroup.li [] [ text name ]


viewPlayers : String -> Dict String (List JD.Value) -> Html Msg
viewPlayers playerName presence =
    let
        players =
            ListGroup.ul
                (List.map (viewPlayer playerName) (Dict.toList presence))
    in
    Card.config []
        |> Card.header [] [ text "Players" ]
        |> Card.block [] [ Block.custom players ]
        |> Card.view


view : Session -> Model -> Html Msg
view session model =
    case session.room of
        Nothing ->
            text "You need to join a room."

        Just room ->
            let
                name =
                    case session.user of
                        Just user ->
                            user.username

                        Nothing ->
                            ""
            in
            div []
                [ h1 [] [ text room.name ]
                , Grid.container []
                    [ Grid.row []
                        [ Grid.col [ Col.sm8 ] [ viewChat name model.chat ]
                        , Grid.col [ Col.sm4 ] [ viewPlayers name model.presence ]
                        ]
                    ]
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
        |> Socket.onClose (\_ -> GoToHomePage)
        |> Socket.onAbnormalClose (\_ -> GoToHomePage)
        |> Socket.reconnectTimer (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)


getChannel : Session -> Channel Msg
getChannel session =
    let
        params =
            case session.user of
                Just user ->
                    [ ( "username", JE.string user.username ) ]

                Nothing ->
                    -- TODO: redirect to home
                    []

        roomRoute =
            case session.room of
                -- TODO: redirect to home
                Nothing ->
                    ""

                Just room ->
                    roomChannel room

        presence =
            Presence.create
                |> Presence.onChange UpdatePresence
    in
    Channel.init roomRoute
        |> Channel.withPayload (JE.object params)
        |> Channel.onRequestJoin (SetRoomState JoiningRoom)
        |> Channel.onJoin (\_ -> SetRoomState JoinedRoom)
        |> Channel.onLeave (\_ -> GoToHomePage)
        |> Channel.on "newMessage" (\msg -> NewMsg msg)
        |> Channel.withPresence presence
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
    = GoToHomePage
    | MessageInput String
    | MessageKeyDown Int
    | SubmitMessage
    | SetSocketState SocketState
    | SetRoomState RoomState
    | NewMsg JD.Value
    | NewSystemMessage String
    | UpdatePresence (Dict String (List JD.Value))



--| SetChannel (Channel Msg)


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        GoToHomePage ->
            model ! [ Route.modifyUrl Route.Home ]

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
            case session.room of
                Nothing ->
                    model ! []

                Just room ->
                    if String.length model.chat.chatInput == 0 then
                        model ! []
                    else
                        let
                            newChat =
                                { chatInput = "", messages = model.chat.messages }

                            push =
                                Push.init (roomChannel room) "message"
                                    |> Push.withPayload (JE.object [ ( "msg", JE.string model.chat.chatInput ) ])
                        in
                        { model | chat = newChat } ! [ Phoenix.push socketUrl push ]

        SetSocketState newSocketState ->
            { model | socketState = newSocketState } ! []

        SetRoomState newRoomState ->
            let
                message =
                    case newRoomState of
                        LeftRoom ->
                            "Left room."

                        JoinedRoom ->
                            "Joined room."

                        JoiningRoom ->
                            "Joining room."
            in
            update session (NewSystemMessage message) { model | roomState = newRoomState }

        NewSystemMessage message ->
            let
                newMessages =
                    model.chat.messages ++ [ SystemMessage message ]

                newChat =
                    { chatInput = model.chat.chatInput, messages = newMessages }
            in
            { model | chat = newChat } ! [ Cmd.none ]

        NewMsg payload ->
            case JD.decodeValue decodeChatMsg payload of
                Ok msg ->
                    let
                        newMessages =
                            model.chat.messages ++ [ UserMessage msg.userName msg.message ]

                        newChat =
                            { chatInput = model.chat.chatInput, messages = newMessages }
                    in
                    { model | chat = newChat } ! []

                Err err ->
                    update session (NewSystemMessage ("Error: " ++ err)) model

        UpdatePresence presenceState ->
            { model | presence = Debug.log "presenceState " presenceState }
                ! []
