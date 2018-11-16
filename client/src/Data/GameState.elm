module Data.GameState exposing (..)

import Json.Decode exposing (..)


-- Models


type alias GameState =
    { state : FsmState
    , gameStateData : FsmModel
    }


type alias FsmModel =
    { succeededCount : Int
    , rejectCount : Int
    , failedCount : Int
    }


type FsmState
    = Invalid String
    | Waiting
    | BuildTeam
    | TeamVote
    | OnQuest
    | GameEndEvil
    | GameEndAssassin
    | GameEndGood



-- JSON Decoding


decodeGameState : Decoder GameState
decodeGameState =
    map2 GameState
        (field "state" decodeGameFsmState)
        (field "data" decodeGameFsmData)


decodeGameFsmState : Decoder FsmState
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

                    "game_end_good_assassin" ->
                        succeed GameEndAssassin

                    "game_end_good" ->
                        succeed GameEndGood

                    unknown ->
                        succeed (Invalid unknown)
            )


decodeGameFsmData : Decoder FsmModel
decodeGameFsmData =
    map3 FsmModel
        (field "succeeded_count" int)
        (field "reject_count" int)
        (field "failed_count" int)
