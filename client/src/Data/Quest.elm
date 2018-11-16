module Data.Quest exposing (..)

import Data.Team exposing (..)
import Json.Decode exposing (..)


type alias Quest =
    { active : Bool
    , state : String
    , team : Team
    , num_fails_required : Int
    , quest_card_players : List String
    , quest_cards : List String
    }


decodeQuest : Decoder Quest
decodeQuest =
    map6 Quest
        (field "active" bool)
        (field "state" string)
        (field "team"
            decodeTeam
        )
        (field "num_fails_required" int)
        (field "quest_card_players" (list string))
        (field "quest_cards" (list string))
