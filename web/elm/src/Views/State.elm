module Views.State exposing (frame)

import Html exposing (..)
import Html.Attributes exposing (..)


frame : Html msg -> Html msg
frame content =
    div [ class "page-frame" ]
        [ viewHeader
        , content
        , viewFooter
        ]


viewHeader : Html msg
viewHeader =
    nav [ class "navbar navbar-light" ]
        [ text "Header" ]


viewFooter : Html msg
viewFooter =
    footer []
        [ text "Footer" ]
