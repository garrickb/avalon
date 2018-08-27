module Scene.Home exposing (ExternalMsg(..), Model, Msg, init, update, view)

import Data.Room as Room
import Data.Session exposing (Session)
import Data.User as User
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
        , input [ onInput InputUserName, placeholder "User Name" ] []
        , input [ onInput InputRoomName, placeholder "Room Name" ] []
        , button [ onClick JoinRoom ] [ text "go to room" ]
        ]



-- UPDATE --


type Msg
    = InputRoomName String
    | InputUserName String
    | JoinRoom


type ExternalMsg
    = NoOp
    | SetSessionInfo (Maybe Room.Room) (Maybe User.User)


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        InputRoomName name ->
            ( ( { model | roomName = name }, Cmd.none ), NoOp )

        InputUserName name ->
            ( ( { model | userName = name }, Cmd.none ), NoOp )

        JoinRoom ->
            let
                user =
                    { username = model.userName }

                lobby =
                    { name = model.roomName }
            in
            ( ( model, Cmd.batch [ Route.modifyUrl Route.Room ] ), SetSessionInfo (Just lobby) (Just user) )
