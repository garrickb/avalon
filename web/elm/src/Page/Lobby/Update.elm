module Page.Lobby.Update exposing (update)

import Page.Lobby.Message exposing (..)
import Page.Lobby.Model exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Todo ->
            ( model, Cmd.none )
