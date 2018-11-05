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
    , lobbyName : String
    }


init : Model
init =
    { userName = "", lobbyName = "" }



-- VIEW --


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


view : Session -> Model -> Html Msg
view session model =
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ h1 [ style [ ( "text-align", "center" ) ] ] [ text "Avalon" ]
            , Card.config []
                |> Card.block []
                    [ Block.text []
                        [ Form.group []
                            [ Form.label [] [ text "Username" ]
                            , Input.text [ Input.attrs [ value model.userName, onInput InputUserName, placeholder "Username" ] ]
                            ]
                        , Form.group []
                            [ Form.label [] [ text "Lobby Name" ]
                            , Input.text [ Input.attrs [ value model.lobbyName, onInput InputLobbyName, onKeyDown LobbyNameKeyDown, placeholder "Lobby Name" ] ]
                            ]
                        , div [ class "text-center" ] [ Button.button [ Button.primary, Button.attrs [ onClick JoinLobby ] ] [ text "Join Lobby" ] ]
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
    = InputLobbyName String
    | InputUserName String
    | LobbyNameKeyDown Int
    | JoinLobby


type ExternalMsg
    = NoOp
    | SetSessionInfo (Maybe String) (Maybe String)


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        InputLobbyName name ->
            ( ( { model | lobbyName = name }, Cmd.none ), NoOp )

        InputUserName name ->
            ( ( { model | userName = name }, Cmd.none ), NoOp )

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
                ( ( model, Cmd.batch [ Route.modifyUrl Route.Lobby ] )
                , SetSessionInfo (Just lobbyName) (Just userName)
                )
            else
                ( ( model, Cmd.none ), NoOp )
