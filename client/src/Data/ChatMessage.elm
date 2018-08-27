module Data.ChatMessage exposing (ChatMsg, decodeChatMsg)

import Json.Decode as JD exposing (Decoder)


-- MODEL --


type alias ChatMsg =
    { userName : String, message : String }



-- DECODER --


decodeChatMsg : Decoder ChatMsg
decodeChatMsg =
    JD.map2 (\userName msg -> { userName = userName, message = msg })
        (JD.field "username" JD.string)
        (JD.field "msg" JD.string)
