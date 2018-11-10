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
    , num_players_required : Int
    , num_fails_required : Int
    , outcome : String
    , num_fails : Maybe Int
    , selected_players : List String
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
        (field "num_players_required" int)
        (field "num_fails_required" int)
        (field "outcome" string)
        (field "num_fails" (maybe int))
        (field "selected_players" (list string))


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
