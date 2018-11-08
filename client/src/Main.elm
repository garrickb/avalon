module Main exposing (main)

import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Data.Session exposing (Session, initialSession)
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Route exposing (Route)
import Scene.Home as Home
import Scene.Lobby as Lobby
import Task


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
        { session = initialSession
        , state = initialState
        }


initialState : State
initialState =
    Blank



-- VIEW --


view : Model -> Html Msg
view model =
    Grid.container []
        [ CDN.stylesheet
        , viewState model.session model.state
        ]


viewState : Session -> State -> Html Msg
viewState session state =
    case state of
        Blank ->
            -- TODO: Display a spinner to show the page is loading
            Html.text ""

        NotFound ->
            -- TODO: Route to home with an error visible
            Html.text "Page Not Found"

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
        [ stateSubscriptions model ]


stateSubscriptions : Model -> Sub Msg
stateSubscriptions model =
    case model.state of
        Blank ->
            Sub.none

        NotFound ->
            Sub.none

        Lobby _ ->
            Sub.map LobbyMsg (Lobby.subscription model.session)

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
            ( { model | state = Home (Home.init model.session) }, Route.modifyUrl Route.Home )

        Just Route.Home ->
            ( { model | state = Home (Home.init model.session) }, Cmd.none )

        Just Route.Lobby ->
            let
                ( newState, cmd ) =
                    case model.session.lobbyName of
                        Nothing ->
                            ( Home (Home.init model.session), Route.modifyUrl Route.Home )

                        Just lobby ->
                            ( Lobby Lobby.init, Cmd.none )
            in
            ( { model | state = newState }, cmd )


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

                        Home.SetSessionInfo lobby user ->
                            let
                                oldSession =
                                    model.session

                                newSession =
                                    { oldSession | userName = user, lobbyName = lobby }
                            in
                            { model | session = newSession }
            in
            ( { newModel | state = Home stateModel }, Cmd.map HomeMsg cmd )

        ( LobbyMsg subMsg, Lobby subModel ) ->
            let
                ( stateModel, cmd ) =
                    Lobby.update model.session subMsg subModel
            in
            ( { model | state = Lobby stateModel }, Cmd.map LobbyMsg cmd )

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
