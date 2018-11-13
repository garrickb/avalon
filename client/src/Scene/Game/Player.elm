module Scene.Game.Player exposing (..)

import Data.Game exposing (Alignment(..), GameFsmState(..), Player, Quest)
import Html exposing (..)
import Html.Attributes exposing (..)


type Modifier
    = Ready Bool
    | King
    | IsOnQuest Bool
    | HasVotedOnTeam Bool
    | AcceptedTeam Bool
    | PlayedQuestCard Bool


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

        IsOnQuest val ->
            if val then
                span [ class (classes ++ "fa-shield-alt"), style [ ( "color", "#B8860B" ) ] ] []
            else
                text ""

        HasVotedOnTeam val ->
            if val then
                span [] [ text "(voted)" ]
            else
                span [] []

        AcceptedTeam val ->
            if val then
                span [] [ text "(accepted)" ]
            else
                span [] [ text "(rejected)" ]

        PlayedQuestCard val ->
            if val then
                span [] [ text "(played)" ]
            else
                text ""


viewName : Player -> GameFsmState -> Maybe Quest -> Html msg
viewName player state maybeQuest =
    let
        name =
            if player.role.alignment /= AlignmentUnknown then
                player.name ++ " (" ++ toString player.role.alignment ++ ")"
            else
                player.name

        playerName =
            if player.king then
                span [] [ viewModifier King, text (" " ++ name) ]
            else
                text name
    in
    case maybeQuest of
        Nothing ->
            playerName

        Just quest ->
            case state of
                Waiting ->
                    span [] [ playerName, text " ", viewModifier (Ready player.ready) ]

                TeamVote ->
                    let
                        hasVoted =
                            List.any (\tuple -> Tuple.first tuple == player.name) quest.team.votes
                    in
                    span [] [ playerName, text " ", viewModifier (IsOnQuest (List.member player.name quest.team.players)), viewModifier (HasVotedOnTeam hasVoted) ]

                OnQuest ->
                    let
                        votedToAccept =
                            List.any (\tuple -> tuple == ( player.name, "accept" )) quest.team.votes

                        playedQuestCard =
                            List.member player.name quest.quest_card_players

                        onQuest =
                            List.member player.name quest.team.players
                    in
                    span [] [ playerName, text " ", viewModifier (IsOnQuest onQuest), viewModifier (AcceptedTeam votedToAccept), viewModifier (PlayedQuestCard playedQuestCard) ]

                _ ->
                    span [] [ playerName, text " ", viewModifier (IsOnQuest (List.member player.name quest.team.players)) ]
