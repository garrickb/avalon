module Scene.Game exposing (Msg(..), pushMessage, pushMessageWithPayload, update, view, viewAssassinateButton, viewBeginVotingButton, viewBoard, viewGameRestartButton, viewPlayerActions, viewPlayerOther, viewPlayerSelf, viewPlayers, viewQuestCardButtons, viewQuestSelectButton, viewVotingButtons)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Utilities.Spacing as Spacing
import Data.Game exposing (Game, GameScene)
import Data.GameState exposing (FsmState(..))
import Data.Player exposing (Player)
import Data.Quest as Quest exposing (Quest)
import Data.Role exposing (Alignment(..), RoleType(..))
import Data.RoomChannel as RoomChannel exposing (roomChannelName)
import Data.Session exposing (Session)
import Data.Socket exposing (SocketState(..), socketUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Encode as JE
import Phoenix
import Phoenix.Push as Push
import Scene.Game.Player as PlayerView
import Scene.Game.Quest



-- VIEW --


viewRejectCounter : Int -> Html Msg
viewRejectCounter rejectCount =
    text ("Reject Counter: " ++ toString rejectCount)


viewBoard : GameScene -> Game -> Html Msg
viewBoard scene game =
    let
        activeQuest =
            Quest.activeQuest game.quests

        quests =
            Html.map QuestMsg <| Scene.Game.Quest.view scene.questScene game.quests
    in
    Grid.row
        [ Row.centerXs, Row.attrs [ style [ ( "height", "100vh" ), ( "overflow", "auto" ), ( "text-align", "center" ) ] ] ]
        [ Grid.col [ Col.middleXs ]
            [ Card.config []
                |> Card.block [ Block.attrs [ style [ ( "padding", "5px" ) ] ] ]
                    [ Block.text []
                        [ quests
                        , viewRejectCounter game.fsm.gameStateData.rejectCount
                        , text (", # Evil: " ++ toString game.numEvil)
                        ]
                    ]
                |> Card.view
            ]
        ]


view : Session -> GameScene -> Game -> Html Msg
view session scene game =
    let
        username =
            Maybe.withDefault "" session.userName

        maybeSelf =
            List.head <| List.filter (\p -> p.name == username) game.players

        activeQuest =
            Quest.activeQuest game.quests
    in
    div []
        [ viewBoard scene game
        , viewPlayers game.players maybeSelf game.fsm.state activeQuest
        , viewPlayerSelf game.fsm.state activeQuest maybeSelf
        ]


viewPlayerOther : FsmState -> Maybe Quest -> Maybe Player -> Player -> Grid.Column Msg
viewPlayerOther state quest self player =
    let
        playerAction =
            viewPlayerActions state player self
    in
    Grid.col []
        [ Card.config []
            |> Card.block []
                [ Block.text []
                    [ PlayerView.viewName player state quest
                    , viewPlayerActions state player self quest
                    ]
                ]
            |> Card.view
        ]


viewPlayerSelf : FsmState -> Maybe Quest -> Maybe Player -> Html Msg
viewPlayerSelf state quest maybeSelf =
    let
        content =
            case maybeSelf of
                Just self ->
                    -- Player's view of themselves
                    Card.config []
                        |> Card.block []
                            [ Block.text []
                                [ h5 [] [ PlayerView.viewName self state quest ]
                                , hr [] []
                                , p [] []
                                , viewPlayerActions state self (Just self) quest
                                ]
                            ]
                        |> Card.view

                Nothing ->
                    -- Spectator's view of themselves
                    text ""
    in
    Grid.row
        [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "bottom", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
        [ Grid.col []
            [ content ]
        ]


viewPlayers : List Player -> Maybe Player -> FsmState -> Maybe Quest -> Html Msg
viewPlayers players maybeSelf state quest =
    case maybeSelf of
        Nothing ->
            let
                half =
                    round (toFloat (List.length players) / 2)

                firstHalf =
                    List.take half players

                secondHalf =
                    List.drop half players
            in
            span []
                [ Grid.row
                    [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
                    (firstHalf |> List.map (viewPlayerOther state quest Nothing))
                , Grid.row
                    [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "bottom", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
                    (secondHalf |> List.map (viewPlayerOther state quest Nothing))
                ]

        Just self ->
            let
                selfIndex =
                    case maybeSelf of
                        Nothing ->
                            -1

                        Just self ->
                            Maybe.withDefault -1
                                (players
                                    |> List.indexedMap (,)
                                    |> List.filter (\( i, p ) -> self.name == p.name)
                                    |> List.map (\( i, p ) -> i)
                                    |> List.head
                                )

                beforeSelf =
                    players
                        |> List.indexedMap (,)
                        |> List.filter (\( i, p ) -> i < selfIndex)
                        |> List.map (\( i, p ) -> p)

                afterSelf =
                    players
                        |> List.indexedMap (,)
                        |> List.filter (\( i, p ) -> i > selfIndex)
                        |> List.map (\( i, p ) -> p)

                orderedPlayers =
                    List.append afterSelf beforeSelf

                content =
                    orderedPlayers
                        |> List.map (viewPlayerOther state quest maybeSelf)
            in
            Grid.row
                [ Row.middleXs, Row.attrs [ class "position-absolute text-center", style [ ( "top", "15px" ), ( "left", "15px" ), ( "width", "100%" ) ] ] ]
                content


viewPlayerActions : FsmState -> Player -> Maybe Player -> Maybe Quest -> Html Msg
viewPlayerActions state player maybeSelf maybeQuest =
    case maybeSelf of
        Nothing ->
            -- Spectator has no actions
            text ""

        Just self ->
            -- Viewing your own actions
            if player.name == self.name then
                case state of
                    Waiting ->
                        let
                            roleDescription =
                                case player.role.name of
                                    Servant ->
                                        text "You are a loyal servant of King Arthur"

                                    Minion ->
                                        text "You are a minion of mordred"

                                    Merlin ->
                                        -- Except Mordred, if the setting is enabled
                                        text "You know all evil"

                                    Assassin ->
                                        -- If Merlin is enabled
                                        text "If evil loses, you have the chance to win if you can guess who Merlin is and assassinate him"

                                    Percival ->
                                        -- You also see Morgana, if the setting is enabled
                                        text "You know who Merlin is"

                                    Mordred ->
                                        -- If Merlin is enabled
                                        text "Your identity is not revealed to Merlin"

                                    Oberon ->
                                        text "You gain no knowledge of other Evil players, nor do they gain knowledge of you"

                                    Morgana ->
                                        text "You appear to be Merlin to Percival"

                                    RoleUnknown ->
                                        text "You are an unknown role."

                            buttonText =
                                if player.ready then
                                    "Waiting..."

                                else
                                    "Ready"
                        in
                        div []
                            [ p [ class "text-muted" ] [ text ("You are " ++ toString player.role.name ++ ", who is " ++ toString player.role.alignment ++ "") ]
                            , p [] [ roleDescription ]
                            , Button.button [ Button.primary, Button.attrs [ onClick PlayerReady ], Button.disabled player.ready ] [ text buttonText ]
                            ]

                    BuildTeam ->
                        let
                            numberOfPlayers =
                                case maybeQuest of
                                    Nothing ->
                                        -1

                                    Just quest ->
                                        quest.team.num_players_required
                        in
                        if player.king then
                            div []
                                [ p [] [ text ("Select your " ++ toString numberOfPlayers ++ " team members") ]
                                , viewQuestSelectButton self maybeQuest
                                , viewBeginVotingButton maybeQuest
                                ]

                        else
                            text "waiting for quest members to be selected"

                    TeamVote ->
                        case maybeQuest of
                            Just quest ->
                                if List.any (\tuple -> Tuple.first tuple == player.name) quest.team.votes then
                                    text "Waiting for everyone else to vote..."

                                else
                                    viewVotingButtons

                            Nothing ->
                                text "Invalid quest"

                    OnQuest ->
                        viewQuestCardButtons player maybeQuest

                    GameEndEvil ->
                        div []
                            [ div [] [ text "Evil Wins!" ]
                            , viewGameRestartButton
                            ]

                    GameEndAssassin ->
                        if player.role.name == Assassin then
                            text "Good wins? You have a chance to guess who Merlin is."

                        else
                            text "Good wins? The Assassin has a chance to guess who Merlin is."

                    GameEndGood ->
                        div []
                            [ div [] [ text "Good Wins!" ]
                            , viewGameRestartButton
                            ]

                    Invalid state ->
                        text ("unknown game state: " ++ state)

            else
                -- Viewing actions on another player
                case state of
                    BuildTeam ->
                        if self.king then
                            div [] [ viewQuestSelectButton player maybeQuest ]

                        else
                            text ""

                    GameEndAssassin ->
                        if self.role.name == Assassin then
                            div [] [ viewAssassinateButton player ]

                        else
                            text ""

                    _ ->
                        text ""


viewVotingButtons : Html Msg
viewVotingButtons =
    div []
        [ text "Vote on the team:"
        , div []
            [ Button.button [ Button.outlineSuccess, Button.attrs [ Spacing.ml1, onClick AcceptVote ] ] [ text "Accept" ]
            , Button.button [ Button.outlineDanger, Button.attrs [ Spacing.ml1, onClick RejectVote ] ] [ text "Reject" ]
            ]
        ]


viewBeginVotingButton : Maybe Quest -> Html Msg
viewBeginVotingButton questMaybe =
    case questMaybe of
        Nothing ->
            text ""

        Just quest ->
            if List.length quest.team.players == quest.team.num_players_required then
                Button.button [ Button.outlinePrimary, Button.attrs [ Spacing.ml1, onClick BeginVoting ] ] [ text "Begin Voting" ]

            else
                text ""


viewAssassinateButton : Player -> Html Msg
viewAssassinateButton player =
    Button.button
        [ Button.danger
        , Button.attrs [ onClick (AssassinatePlayer player) ]
        ]
        [ span [ class "fa fa-skull-crossbones" ] [] ]


viewGameRestartButton : Html Msg
viewGameRestartButton =
    Button.button
        [ Button.outlinePrimary
        , Button.attrs [ onClick RestartGame ]
        ]
        [ text "Restart Game" ]


viewQuestSelectButton : Player -> Maybe Quest -> Html Msg
viewQuestSelectButton player maybeQuest =
    let
        onQuest =
            case maybeQuest of
                Nothing ->
                    False

                Just quest ->
                    List.member player.name quest.team.players
    in
    if onQuest then
        Button.button [ Button.outlineWarning, Button.attrs [ onClick (DeselectQuestMember player) ] ] [ text "Remove" ]

    else
        Button.button [ Button.outlineInfo, Button.attrs [ onClick (SelectQuestMember player) ] ] [ text "Select" ]


viewQuestCardButtons : Player -> Maybe Quest -> Html Msg
viewQuestCardButtons player maybeQuest =
    let
        buttons =
            case maybeQuest of
                Nothing ->
                    [ text "Invalid quest" ]

                Just quest ->
                    if List.member player.name quest.team.players then
                        if List.member player.name quest.quest_card_players then
                            [ text "Waiting for other quest members to play a quest card..." ]

                        else if player.role.alignment == Evil then
                            [ text "Play a quest card:"
                            , div []
                                [ Button.button [ Button.success, Button.attrs [ Spacing.ml1, onClick PlayQuestSuccessCard ] ]
                                    [ text "Success" ]
                                , Button.button
                                    [ Button.danger, Button.attrs [ Spacing.ml1, onClick PlayQuestFailCard ] ]
                                    [ text "Fail" ]
                                ]
                            ]

                        else
                            [ Button.button [ Button.success, Button.attrs [ onClick PlayQuestSuccessCard ] ]
                                [ text "Success" ]
                            ]

                    else
                        [ text "Waiting for all quest members to play a quest card..." ]
    in
    span [] buttons


type Msg
    = StopGame
    | PlayerReady
    | SelectQuestMember Player
    | DeselectQuestMember Player
    | BeginVoting
    | AcceptVote
    | RejectVote
    | PlayQuestSuccessCard
    | PlayQuestFailCard
    | AssassinatePlayer Player
    | RestartGame
    | QuestMsg Scene.Game.Quest.Msg


update : String -> Session -> Msg -> Game -> GameScene -> ( GameScene, Cmd Msg )
update room session msg game model =
    case msg of
        QuestMsg msg ->
            let
                ( newQuestScene, cmd ) =
                    Scene.Game.Quest.update msg model.questScene
            in
            { model | questScene = newQuestScene } ! []

        StopGame ->
            model ! [ pushMessage room "game:stop" ]

        PlayerReady ->
            model ! [ pushMessage room "player:ready" ]

        SelectQuestMember player ->
            model ! [ pushMessageWithPayload room "team:select_player" [ ( "player", JE.string player.name ) ] ]

        DeselectQuestMember player ->
            model ! [ pushMessageWithPayload room "team:deselect_player" [ ( "player", JE.string player.name ) ] ]

        BeginVoting ->
            model ! [ pushMessage room "team:begin_voting" ]

        AcceptVote ->
            model ! [ pushMessage room "team:accept_vote" ]

        RejectVote ->
            model ! [ pushMessage room "team:reject_vote" ]

        PlayQuestSuccessCard ->
            model ! [ pushMessage room "quest:success" ]

        PlayQuestFailCard ->
            model ! [ pushMessage room "quest:fail" ]

        AssassinatePlayer player ->
            model ! [ pushMessageWithPayload room "player:assassinate" [ ( "player", JE.string player.name ) ] ]

        RestartGame ->
            model ! [ pushMessage room "game:restart" ]


pushMessage : String -> String -> Cmd msg
pushMessage room message =
    Push.init (roomChannelName room) message
        |> Phoenix.push socketUrl


pushMessageWithPayload : String -> String -> List ( String, JE.Value ) -> Cmd msg
pushMessageWithPayload room message payload =
    Push.init (roomChannelName room) message
        |> Push.withPayload (JE.object payload)
        |> Phoenix.push socketUrl
