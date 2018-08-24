module Scene.Home exposing (ExternalMsg(..), Model, Msg, init, update, view)

import Data.Lobby as Lobby
import Data.LobbyName as LobbyName
import Data.Session exposing (Session)
import Data.User as User
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
        , input [ onInput InputUserName, placeholder "User Name" ] []
        , input [ onInput InputLobbyName, placeholder "Lobby Name" ] []
        , button [ onClick JoinLobby ] [ text "go to lobby" ]
        ]



-- UPDATE --


type Msg
    = InputLobbyName String
    | InputUserName String
    | JoinLobby


type ExternalMsg
    = NoOp
    | SetSessionInfo (Maybe Lobby.Lobby) (Maybe User.User)


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
                    { name = model.lobbyName }
            in
            ( ( model, Cmd.batch [ Route.modifyUrl Route.Lobby ] ), SetSessionInfo (Just lobby) (Just user) )
