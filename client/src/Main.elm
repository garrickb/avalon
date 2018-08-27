module Main exposing (main)

import Data.Session exposing (Session, initialSession)
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Route exposing (Route)
import Scene.Home as Home
import Scene.Room as Room
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
    | Room Room.Model


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
    viewState model.session model.state


viewState : Session -> State -> Html Msg
viewState session state =
    case state of
        Blank ->
            -- TODO: Display a spinner to show the page is loading
            Html.text ""

        NotFound ->
            -- TODO: Route to home with an error visible
            Html.text "Page Not Found"

        Room subModel ->
            Room.view session subModel
                |> Html.map RoomMsg

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

        Room _ ->
            Sub.map RoomMsg (Room.subscription model.session)

        Home _ ->
            Sub.none



-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | RoomMsg Room.Msg
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

        Just Route.Room ->
            let
                ( newState, cmd ) =
                    case model.session.room of
                        Nothing ->
                            ( Home Home.init, Route.modifyUrl Route.Home )

                        Just room ->
                            ( Room Room.init, Cmd.none )
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

                        Home.SetSessionInfo room user ->
                            let
                                oldSession =
                                    model.session

                                newSession =
                                    { oldSession | user = user, room = room }
                            in
                            { model | session = newSession }
            in
            ( { newModel | state = Home stateModel }, Cmd.map HomeMsg cmd )

        ( RoomMsg subMsg, Room subModel ) ->
            let
                ( stateModel, cmd ) =
                    Room.update model.session subMsg subModel
            in
            ( { model | state = Room stateModel }, Cmd.map RoomMsg cmd )

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
