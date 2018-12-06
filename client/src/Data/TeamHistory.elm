module Data.TeamHistory exposing (TeamHistory, decodeTeamHistory)

import Data.Team exposing (Team, decodeTeam)
import Json.Decode exposing (..)


type alias TeamHistory =
    { team : Team
    , king : String
    }


decodeTeamHistory : Decoder TeamHistory
decodeTeamHistory =
    map2 TeamHistory
        (field "team" decodeTeam)
        (field "king" string)
