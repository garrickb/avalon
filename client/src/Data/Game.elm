module Data.Game exposing (Game, Player, decodeGame)

import Json.Decode as JD exposing (Decoder)


type alias Game =
    { name : String
    , players : List Player
    , fsm : GameState
    }


type alias GameState =
    { state : String
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


decodeGame : Decoder Game
decodeGame =
    JD.map3 Game
        (JD.field "name" JD.string)
        (JD.field "players" (JD.list decodePlayer))
        (JD.field "fsm" decodeGameState)


decodeGameState : Decoder GameState
decodeGameState =
    JD.map2 GameState
        (JD.field "state" JD.string)
        (JD.field "data" decodeGameStateData)


decodeGameStateData : Decoder GameStateData
decodeGameStateData =
    JD.map3 GameStateData
        (JD.field "succeeded_count" JD.int)
        (JD.field "reject_count" JD.int)
        (JD.field "failed_count" JD.int)


decodePlayer : Decoder Player
decodePlayer =
    JD.map4 Player
        (JD.field "name" JD.string)
        (JD.field "role" JD.string)
        (JD.field "ready" JD.bool)
        (JD.field "king" JD.bool)
