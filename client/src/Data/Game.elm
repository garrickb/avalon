module Data.Game exposing (Alignment(..), Game, GameFsmState(..), Player, Quest, RoleType(..), Room, Settings, decodeGame, decodeRoom)

import Json.Decode exposing (..)


type GameFsmState
    = Invalid String
    | Waiting
    | BuildTeam
    | TeamVote
    | OnQuest
    | GameEndEvil
    | GameEndAssassin
    | GameEndGood


type Alignment
    = AlignmentUnknown
    | Good
    | Evil


type RoleType
    = RoleUnknown
    | Servant
    | Minion
    | Merlin
    | Assassin
    | Percival
    | Mordred
    | Oberon
    | Morgana


type alias Room =
    { id : String
    , settings : Settings
    , game : Maybe Game
    }


type alias Settings =
    { merlin : Bool
    , assassin : Bool
    , percival : Bool
    , mordred : Bool
    , oberon : Bool
    , morgana : Bool
    }


type alias Game =
    { players : List Player
    , numEvil : Int
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
    , role : Role
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


type alias Role =
    { name : RoleType
    , alignment : Alignment
    }


decodeRoom : Decoder Room
decodeRoom =
    map3 Room
        (field "id" string)
        (field "settings" decodeSettings)
        (field "game" (maybe decodeGame))


decodeSettings : Decoder Settings
decodeSettings =
    map6 Settings
        (field "merlin" bool)
        (field "assassin" bool)
        (field "percival" bool)
        (field "mordred" bool)
        (field "oberon" bool)
        (field "morgana" bool)


decodeGame : Decoder Game
decodeGame =
    map4 Game
        (field "players" (list decodePlayer))
        (field "num_evil" int)
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

                    "game_end_good_assassin" ->
                        succeed GameEndAssassin

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
        (field "role" decodeRole)
        (field "ready" bool)
        (field "king" bool)


decodeRoleType : Decoder RoleType
decodeRoleType =
    string
        |> andThen
            (\str ->
                case str of
                    "merlin" ->
                        succeed Merlin

                    "assassin" ->
                        succeed Assassin

                    "percival" ->
                        succeed Percival

                    "mordred" ->
                        succeed Mordred

                    "oberon" ->
                        succeed Oberon

                    "morgana" ->
                        succeed Morgana

                    "unknown" ->
                        succeed RoleUnknown

                    "minion" ->
                        succeed Minion

                    "servant" ->
                        succeed Servant

                    unknown ->
                        fail ("Unknown role: " ++ unknown)
            )


decodeRoleAlignment : Decoder Alignment
decodeRoleAlignment =
    string
        |> andThen
            (\str ->
                case str of
                    "good" ->
                        succeed Good

                    "evil" ->
                        succeed Evil

                    "unknown" ->
                        succeed AlignmentUnknown

                    unknown ->
                        fail ("Unknown alignment" ++ unknown)
            )


decodeRole : Decoder Role
decodeRole =
    map2 Role
        (field "name" decodeRoleType)
        (field "alignment" decodeRoleAlignment)
