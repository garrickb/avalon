module Data.Quest exposing (Quest, QuestScene, activeQuest, decodeQuest, initQuestScene)

import Bootstrap.Tab as Tab
import Data.Team exposing (..)
import Data.TeamHistory exposing (..)
import Json.Decode exposing (..)


type alias Quest =
    { active : Bool
    , state : String
    , team : Team
    , team_history : List TeamHistory
    , num_fails_required : Int
    , quest_card_players : List String
    , quest_cards : List String
    }


type alias QuestScene =
    { tabState : Tab.State
    , selectedQuest : Maybe Quest
    }


initQuestScene : QuestScene
initQuestScene =
    { tabState = Tab.initialState, selectedQuest = Nothing }


decodeQuest : Decoder Quest
decodeQuest =
    map7 Quest
        (field "active" bool)
        (field "state" string)
        (field "team" decodeTeam)
        (field "team_history" (list decodeTeamHistory))
        (field "num_fails_required" int)
        (field "quest_card_players" (list string))
        (field "quest_cards" (list string))


activeQuest : List Quest -> Maybe Quest
activeQuest quests =
    List.head <| List.filter (\q -> q.active == True) quests
