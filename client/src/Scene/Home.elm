module Scene.Home exposing (ExternalMsg(..), Model, Msg, init, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Route exposing (Route)


-- MODEL --


type alias Model =
    { userName : String
    , roomName : String
    }


init : Model
init =
    { userName = "", roomName = "" }



-- VIEW --


view : Session -> Model -> Html Msg
view session model =
    div []
        [ h1 [] [ text "Join a Room" ]
        , Form.group []
            [ Form.label [] [ text "Username" ]
            , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
            ]
        , Form.group []
            [ Form.label [] [ text "Room Name" ]
            , Input.text [ Input.attrs [ value model.roomName, onInput InputRoomName, placeholder "Room Name" ] ]
            ]
        , Button.button [ Button.primary, Button.block, Button.attrs [ onClick JoinRoom ] ] [ text "Join Room" ]
        ]



-- UPDATE --


type Msg
    = InputRoomName String
    | InputUserName String
    | JoinRoom


type ExternalMsg
    = NoOp
    | SetSessionInfo (Maybe String) (Maybe String)


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        InputRoomName name ->
            ( ( { model | roomName = name }, Cmd.none ), NoOp )

        InputUserName name ->
            ( ( { model | userName = name }, Cmd.none ), NoOp )

        JoinRoom ->
            let
                roomName =
                    String.trim model.roomName

                userName =
                    String.trim model.userName
            in
            if (String.length roomName > 0) && (String.length userName > 0) then
                ( ( model, Cmd.batch [ Route.modifyUrl Route.Room ] )
                , SetSessionInfo (Just roomName) (Just userName)
                )
            else
                ( ( model, Cmd.none ), NoOp )
