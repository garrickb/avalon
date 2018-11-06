module Data.Game exposing (Game, decodeGame)

import Json.Decode as JD exposing (Decoder)


type alias Game =
    { name : String
    , players : List String
    , player : Player
    , king : Int
    , state : GameState
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
    }


decodeGame : Decoder Game
decodeGame =
    JD.map5 Game
        (JD.field "name" JD.string)
        (JD.field "players" (JD.list JD.string))
        (JD.field "player" decodePlayer)
        (JD.field "king" JD.int)
        (JD.field "state" decodeGameState)


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
    JD.map2 Player
        (JD.field "name" JD.string)
        (JD.field "role" JD.string)
