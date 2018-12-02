module Data.Game exposing (..)

import Data.GameState exposing (GameState, decodeGameState)
import Data.Player exposing (..)
import Data.Quest exposing (..)
import Json.Decode exposing (..)


type alias Game =
    { players : List Player
    , numEvil : Int
    , quests : List Quest
    , fsm : GameState
    }


type alias GameScene =
    { questScene : QuestScene
    , playerScene : PlayerScene
    }


initGameScene : GameScene
initGameScene =
    { questScene = initQuestScene
    , playerScene = initPlayerScene
    }


decodeGame : Decoder Game
decodeGame =
    map4 Game
        (field "players" (list decodePlayer))
        (field "num_evil" int)
        (field "quests" (list decodeQuest))
        (field "fsm" decodeGameState)
