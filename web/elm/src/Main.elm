module Main exposing (main)

import Data.Session exposing (Session)
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Route exposing (Route)
import Scene.Home as Home
import Scene.Lobby as Lobby
import Task
import Views.State exposing (frame)


-- MODEL --


type alias Model =
    { session : Session
    , state : State
    }


type State
    = Blank
    | NotFound
    | Home Home.Model
    | Lobby Lobby.Model


init : Value -> Location -> ( Model, Cmd Msg )
init val location =
    setRoute (Route.fromLocation location)
        { session = { user = Nothing, lobby = Nothing }
        , state = initialState
        }


initialState : State
initialState =
    Blank



-- VIEW --


view : Model -> Html Msg
view model =
    viewState model.session model.state
        |> frame


viewState : Session -> State -> Html Msg
viewState session state =
    case state of
        Blank ->
            Html.text ""

        NotFound ->
            Html.text "Not Found"

        Lobby subModel ->
            Lobby.view session subModel
                |> Html.map LobbyMsg

        Home subModel ->
            Home.view session subModel
                |> Html.map HomeMsg



-- SUBSCRIPTION --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ stateSubscriptions model.state ]


stateSubscriptions : State -> Sub Msg
stateSubscriptions state =
    case state of
        Blank ->
            Sub.none

        NotFound ->
            Sub.none

        Lobby _ ->
            Sub.none

        Home _ ->
            Sub.none



-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | LobbyMsg Lobby.Msg
    | HomeMsg Home.Msg


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    let
        transition toMsg task =
            ( model, Task.attempt toMsg task )
    in
    case maybeRoute of
        Nothing ->
            ( { model | state = NotFound }, Cmd.none )

        Just Route.Root ->
            ( { model | state = Home Home.init }, Route.modifyUrl Route.Home )

        Just Route.Home ->
            ( { model | state = Home Home.init }, Cmd.none )

        Just Route.Lobby ->
            ( { model | state = Lobby Lobby.init }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updateState model.state msg model


updateState : State -> Msg -> Model -> ( Model, Cmd Msg )
updateState state msg model =
    case ( msg, state ) of
        ( SetRoute route, _ ) ->
            setRoute route model

        ( HomeMsg subMsg, Home subModel ) ->
            let
                ( ( stateModel, cmd ), msgFromPage ) =
                    Home.update subMsg subModel

                newModel =
                    case msgFromPage of
                        Home.NoOp ->
                            model

                        Home.SetSession session ->
                            { model | session = session, state = Lobby Lobby.init }
            in
            ( { newModel | state = Home stateModel }, Cmd.map HomeMsg cmd )

        ( LobbyMsg subMsg, Lobby subModel ) ->
            ( model, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )



-- MAIN --


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
