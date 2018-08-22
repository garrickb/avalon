module Data.LobbyName exposing (LobbyName(..), decoder, encode, toHtml, toString, urlParser)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import UrlParser


-- TYPES


type LobbyName
    = LobbyName String



-- CREATE


decoder : Decoder LobbyName
decoder =
    Decode.map LobbyName Decode.string



-- TRANSFORM


encode : LobbyName -> Value
encode (LobbyName lobbyName) =
    Encode.string lobbyName


toString : LobbyName -> String
toString (LobbyName lobbyName) =
    lobbyName


urlParser : UrlParser.Parser (LobbyName -> a) a
urlParser =
    UrlParser.custom "LOBBYNAME" <| Ok << LobbyName


toHtml : LobbyName -> Html msg
toHtml (LobbyName lobbyName) =
    Html.text lobbyName
