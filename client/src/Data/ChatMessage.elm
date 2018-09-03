module Data.ChatMessage exposing (ChatMessage(..), MessageModel, decodeChatMsg)

import Json.Decode as JD exposing (Decoder)


-- MODEL --


type ChatMessage
    = SystemMessage String
    | UserMessage String String


type alias MessageModel =
    { userName : String, message : String }



-- DECODER --


decodeChatMsg : Decoder MessageModel
decodeChatMsg =
    JD.map2 (\userName msg -> { userName = userName, message = msg })
        (JD.field "username" JD.string)
        (JD.field "msg" JD.string)
