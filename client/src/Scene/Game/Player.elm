module Scene.Game.Player exposing (Modifier(..), alignmentColor, viewModifier, viewName)

import Data.GameState as GameState exposing (..)
import Data.Player exposing (Player, PlayerScene)
import Data.Quest exposing (Quest)
import Data.Role exposing (Alignment(..), RoleType(..))
import Html exposing (..)
import Html.Attributes exposing (..)


type Modifier
    = Ready Bool
    | King
    | IsOnQuest
    | HasVotedOnTeam
    | AcceptedLastTeam Bool
    | AcceptedTeam Bool
    | PlayedQuestCard


viewModifier : Modifier -> Html msg
viewModifier mod =
    let
        classes =
            "fa fa-small "
    in
    case mod of
        King ->
            span [ class (classes ++ "fa-crown"), style [ ( "color", "gold" ), ( "-webkit-text-stroke", "1px #000 " ) ] ] []

        Ready True ->
            span [ class (classes ++ "fa-check-circle"), style [ ( "color", "green" ) ] ] []

        Ready False ->
            span [ class (classes ++ "fa-times-circle"), style [ ( "color", "red" ) ] ] []

        IsOnQuest ->
            span [ class (classes ++ "fa-shield-alt"), style [ ( "color", "#B8860B" ) ] ] []

        HasVotedOnTeam ->
            span [] [ text "(voted)" ]

        AcceptedLastTeam val ->
            if val then
                span [] [ text "(accepted)" ]

            else
                span [] [ text "(rejected)" ]

        AcceptedTeam val ->
            if val then
                span [] [ text "(accepted)" ]

            else
                span [] [ text "(rejected)" ]

        PlayedQuestCard ->
            span [] [ text "(played)" ]


alignmentColor : Alignment -> String
alignmentColor alignment =
    case alignment of
        AlignmentUnknown ->
            "black"

        Evil ->
            "red"

        Good ->
            "green"


viewName : Player -> GameState.FsmState -> PlayerScene -> Maybe Quest -> Html msg
viewName player state scene maybeQuest =
    let
        role =
            if scene.hideInformation then
                text ""

            else
                span [ style [ ( "color", alignmentColor player.role.alignment ) ] ]
                    [ text
                        (if player.role.name /= RoleUnknown then
                            " (" ++ toString player.role.name ++ ")"

                         else if player.role.alignment /= AlignmentUnknown then
                            " (" ++ toString player.role.alignment ++ ")"

                         else
                            ""
                        )
                    ]

        playerName =
            if player.king then
                span [] [ viewModifier King, text " ", text player.name, role ]

            else
                span [] [ text player.name, role ]
    in
    case maybeQuest of
        Nothing ->
            playerName

        Just quest ->
            let
                onQuest =
                    if List.member player.name quest.team.players then
                        viewModifier IsOnQuest

                    else
                        text ""
            in
            case state of
                Waiting ->
                    span [] [ playerName, text " ", viewModifier (Ready player.ready) ]

                BuildTeam ->
                    let
                        lastTeam =
                            List.head quest.team_history

                        lastVote =
                            case lastTeam of
                                Nothing ->
                                    text ""

                                Just history ->
                                    viewModifier (AcceptedLastTeam (List.any (\tuple -> tuple == ( player.name, "accept" )) history.team.votes))
                    in
                    span [] [ playerName, text " ", onQuest, lastVote ]

                TeamVote ->
                    let
                        hasVoted =
                            if List.any (\tuple -> Tuple.first tuple == player.name) quest.team.votes then
                                viewModifier HasVotedOnTeam

                            else
                                text ""
                    in
                    span [] [ playerName, text " ", onQuest, hasVoted ]

                OnQuest ->
                    let
                        votedToAccept =
                            List.any (\tuple -> tuple == ( player.name, "accept" )) quest.team.votes

                        playedQuestCard =
                            if List.member player.name quest.quest_card_players then
                                viewModifier PlayedQuestCard

                            else
                                text ""
                    in
                    span [] [ playerName, text " ", onQuest, viewModifier (AcceptedTeam votedToAccept), playedQuestCard ]

                _ ->
                    span [] [ playerName, text " ", onQuest ]
