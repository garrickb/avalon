module Data.Game exposing (Game, GameFsmState(..), Player, Quest, decodeGame)

import Json.Decode exposing (..)


type GameFsmState
    = Invalid String
    | Waiting
    | BuildTeam
    | TeamVote
    | OnQuest
    | GameEndEvil
    | GameEndGood


type alias Game =
    { name : String
    , players : List Player
    , quests : List Quest
    , fsm : GameState
    }


type alias GameState =
    { state : GameFsmState
    , gameStateData : GameStateData
    }


type alias GameStateData =
    { succeededCount : Int
    , rejectCount : Int
    , failedCount : Int
    }


type alias Player =
    { name : String
    , role : String
    , ready : Bool
    , king : Bool
    }


type alias Quest =
    { active : Bool
    , state : String
    , team : Team
    , num_fails_required : Int
    , quest_card_players : List String
    , quest_cards : List String
    }


type alias Team =
    { players : List String
    , num_players_required : Int
    , votes : List ( String, String )
    }


decodeGame : Decoder Game
decodeGame =
    map4 Game
        (field "name" string)
        (field "players" (list decodePlayer))
        (field "quests" (list decodeQuest))
        (field "fsm" decodeGameState)


decodeQuest : Decoder Quest
decodeQuest =
    map6 Quest
        (field "active" bool)
        (field "state" string)
        (field "team"
            (map3 Team
                (field "players" (list string))
                (field "num_players_required" int)
                (field "votes"
                    (keyValuePairs string)
                )
            )
        )
        (field "num_fails_required" int)
        (field "quest_card_players" (list string))
        (field "quest_cards" (list string))


decodeGameFsmState : Decoder GameFsmState
decodeGameFsmState =
    string
        |> andThen
            (\str ->
                case str of
                    "waiting" ->
                        succeed Waiting

                    "build_team" ->
                        succeed BuildTeam

                    "team_vote" ->
                        succeed TeamVote

                    "quest" ->
                        succeed OnQuest

                    "game_end_evil" ->
                        succeed GameEndEvil

                    "game_end_good" ->
                        succeed GameEndGood

                    unknown ->
                        succeed (Invalid unknown)
            )


decodeGameState : Decoder GameState
decodeGameState =
    map2 GameState
        (field "state" decodeGameFsmState)
        (field "data" decodeGameStateData)


decodeGameStateData : Decoder GameStateData
decodeGameStateData =
    map3 GameStateData
        (field "succeeded_count" int)
        (field "reject_count" int)
        (field "failed_count" int)


decodePlayer : Decoder Player
decodePlayer =
    map4 Player
        (field "name" string)
        (field "role" string)
        (field "ready" bool)
        (field "king" bool)
