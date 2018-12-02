module Data.RoomChannel exposing (roomChannelName)


roomChannelName : String -> String
roomChannelName roomName =
    "room:" ++ roomName
