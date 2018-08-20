module Data.ChatMessage exposing (ChatMessage)

import Data.Player exposing (Player)


type alias ChatMessage =
    { user : Player
    , message : String
    }
