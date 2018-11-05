module Scene.Home exposing (ExternalMsg(..), Model, Msg, init, update, view)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as JD
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


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


view : Session -> Model -> Html Msg
view session model =
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h3 [ style [ ( "text-align", "center" ) ] ] [ text "Welcome to Avalon" ]
            , Card.config []
                |> Card.block []
                    [ Block.text []
                        [ Form.group []
                            [ Form.label [] [ text "Username" ]
                            , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
                            ]
                        , Form.group []
                            [ Form.label [] [ text "Room Name" ]
                            , Input.text [ Input.attrs [ value model.roomName, onInput InputRoomName, onKeyDown RoomNameKeyDown, placeholder "Room Name" ] ]
                            ]
                        , div [ class "text-center" ] [ Button.button [ Button.primary, Button.attrs [ onClick JoinRoom ] ] [ text "Join Room" ] ]
                        ]
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



-- UPDATE --


type Msg
    = InputRoomName String
    | InputUserName String
    | RoomNameKeyDown Int
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
                ( ( model, Cmd.batch [ Route.modifyUrl Route.Room ] )
                , SetSessionInfo (Just roomName) (Just userName)
                )
            else
                ( ( model, Cmd.none ), NoOp )
