module Main exposing (main)

import Bootstrap.Alert as Alert
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Data.Session exposing (Session, SessionMessage(..), initialSession)
import Data.Socket exposing (SocketState(..), socketUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Socket as Socket exposing (Socket)
import Route exposing (Route)
import Scene.Home as Home
import Scene.Lobby as Lobby
import Task


-- MODEL --


type alias Model =
    { session : Session
    , state : State
    , message : SessionMessage
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
        , message = EmptyMsg
        }


initialState : State
initialState =
    Blank



-- VIEW --


view : Model -> Html Msg
view model =
    let
        message =
            case model.message of
                EmptyMsg ->
                    text ""

                InfoMsg msg ->
                    Grid.row
                        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
                        [ Grid.col [ Col.xs12 ] [ Alert.simpleInfo [] [ text msg ] ] ]

                ErrorMsg msg ->
                    Grid.row
                        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
                        [ Grid.col [ Col.xs12 ] [ Alert.simpleDanger [] [ text msg ] ] ]
    in
    Grid.container []
        [ CDN.stylesheet
        , viewState model.session model.state
        , message
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
    let
        socketSubscription =
            Phoenix.connect (socket model.session socketUrl) (stateChannels model)
    in
    Sub.batch [ socketSubscription, stateSubscriptions model ]


stateSubscriptions : Model -> Sub Msg
stateSubscriptions model =
    case model.state of
        _ ->
            Sub.none


stateChannels : Model -> List (Channel Msg)
stateChannels model =
    case model.state of
        Lobby _ ->
            [ Channel.map LobbyMsg (Lobby.getChannel model.session) ]

        _ ->
            []


socket : Session -> String -> Socket Msg
socket session socketUrl =
    Socket.init socketUrl
        |> Socket.onOpen (SetMessage EmptyMsg)
        |> Socket.onClose (\_ -> SetMessage (ErrorMsg "No connection to server."))
        |> Socket.withDebug



-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | LobbyMsg Lobby.Msg
    | HomeMsg Home.Msg
    | SetMessage SessionMessage


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

        ( SetMessage msg, _ ) ->
            ( { model | message = msg }, Cmd.none )

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
