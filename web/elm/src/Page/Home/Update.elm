module Page.Home.Update exposing (..)

import Data.Lobby exposing (Lobby)
import Data.Player exposing (Player)
import Data.Session exposing (Session)
import Page.Home.Message exposing (..)
import Page.Home.Model exposing (Model)


type ExternalMsg
    = NoOp
    | SetPlayerLobby (Maybe Player) (Maybe Lobby)


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        JoinLobby ->
            ( ( model, Cmd.none ), SetPlayerLobby (Just (Player model.username)) (Just (Lobby model.lobbyname Nothing)) )

        UserName name ->
            ( ( { model | username = name }, Cmd.none ), NoOp )

        LobbyName name ->
            ( ( { model | lobbyname = name }, Cmd.none ), NoOp )
