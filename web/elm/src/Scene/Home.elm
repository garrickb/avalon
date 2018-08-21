module Scene.Home exposing (ExternalMsg(..), Model, Msg, init, update, view)

import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Route exposing (Route)


-- MODEL --


type alias Model =
    { userName : String
    , lobbyName : String
    }


init : Model
init =
    { userName = "", lobbyName = "" }



-- VIEW --


view : Session -> Model -> Html Msg
view session model =
    div []
        [ h1 [] [ text "Join a Lobby" ]
        , input [ onInput InputLobbyName, placeholder "User Name" ] []
        , input [ onInput InputUserName, placeholder "Lobby Name" ] []
        , button [ onClick JoinLobby ] [ text "go to lobby" ]
        ]



-- UPDATE --


type Msg
    = InputLobbyName String
    | InputUserName String
    | JoinLobby


type ExternalMsg
    = NoOp
    | SetSession Session


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        InputLobbyName name ->
            ( ( { model | lobbyName = name }, Cmd.none ), NoOp )

        InputUserName name ->
            ( ( { model | userName = name }, Cmd.none ), NoOp )

        JoinLobby ->
            let
                user =
                    { username = model.userName }

                lobby =
                    { name = model.lobbyName, socket = Nothing }

                session =
                    { user = Just user, lobby = Just lobby }
            in
            ( ( model, Cmd.batch [ Route.modifyUrl Route.Lobby ] ), SetSession session )
