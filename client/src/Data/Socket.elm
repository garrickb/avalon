module Data.Socket exposing (SocketState(..), socketUrl)


socketUrl : String
socketUrl =
    "ws://localhost:4000/socket/websocket"


type SocketState
    = SocketClosed
    | SocketOpened
