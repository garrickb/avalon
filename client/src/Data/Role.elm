module Data.Role exposing (..)

import Json.Decode exposing (..)


type alias Role =
    { name : RoleType
    , alignment : Alignment
    }


type Alignment
    = AlignmentUnknown
    | Good
    | Evil


type RoleType
    = RoleUnknown
    | Servant
    | Minion
    | Merlin
    | Assassin
    | Percival
    | Mordred
    | Oberon
    | Morgana



-- Decoders


decodeRole : Decoder Role
decodeRole =
    map2 Role
        (field "name" decodeRoleType)
        (field "alignment" decodeRoleAlignment)


decodeRoleType : Decoder RoleType
decodeRoleType =
    string
        |> andThen
            (\str ->
                case str of
                    "merlin" ->
                        succeed Merlin

                    "assassin" ->
                        succeed Assassin

                    "percival" ->
                        succeed Percival

                    "mordred" ->
                        succeed Mordred

                    "oberon" ->
                        succeed Oberon

                    "morgana" ->
                        succeed Morgana

                    "unknown" ->
                        succeed RoleUnknown

                    "minion" ->
                        succeed Minion

                    "servant" ->
                        succeed Servant

                    unknown ->
                        fail ("Unknown role: " ++ unknown)
            )


decodeRoleAlignment : Decoder Alignment
decodeRoleAlignment =
    string
        |> andThen
            (\str ->
                case str of
                    "good" ->
                        succeed Good

                    "evil" ->
                        succeed Evil

                    "unknown" ->
                        succeed AlignmentUnknown

                    unknown ->
                        fail ("Unknown alignment" ++ unknown)
            )
