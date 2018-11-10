module Scene.Game.Quest exposing (..)

import Data.Game exposing (Quest)
import Html exposing (..)
import Html.Attributes exposing (..)
import Svg
import Svg.Attributes as SvgAttr


viewQuest : Quest -> Svg.Svg msg
viewQuest quest =
    let
        size =
            50

        sizeStr =
            toString size

        halfSizeStr =
            toString (size / 2)

        questMarker =
            if quest.active then
                Svg.circle
                    [ SvgAttr.cx (toString (size - (size / 12)))
                    , SvgAttr.cy (toString (size - (size / 10)))
                    , SvgAttr.r (toString (size / 4))
                    , SvgAttr.fill "#B8860B"
                    , SvgAttr.stroke "black"
                    , SvgAttr.strokeWidth "1.5px"
                    ]
                    []
            else
                Svg.circle
                    [ SvgAttr.cx (toString (size - (size / 12)))
                    , SvgAttr.cy (toString (size - (size / 10)))
                    , SvgAttr.r (toString (size / 4))
                    , SvgAttr.fill "white"
                    , SvgAttr.stroke "black"
                    , SvgAttr.strokeWidth "1px"
                    ]
                    []

        questColor =
            case quest.state of
                "success" ->
                    "green"

                "failure" ->
                    "red"

                _ ->
                    "white"
    in
    span [ style [ ( "padding", "1px" ) ] ]
        [ Svg.svg
            [ SvgAttr.width "60"
            , SvgAttr.height "58.5"
            ]
            [ Svg.circle
                [ SvgAttr.cx (toString ((size / 2) + 1.25))
                , SvgAttr.cy (toString ((size / 2) + 1.25))
                , SvgAttr.r halfSizeStr
                , SvgAttr.fill questColor
                ]
                []
            , Svg.text_
                [ SvgAttr.x "16"
                , SvgAttr.y "38"
                , SvgAttr.fontSize "35"
                , SvgAttr.fill "black"
                ]
                [ Svg.text (toString quest.team.num_players_required) ]
            , Svg.circle
                [ SvgAttr.cx (toString ((size / 2) + 1.25))
                , SvgAttr.cy (toString ((size / 2) + 1.25))
                , SvgAttr.r halfSizeStr
                , SvgAttr.fill "none"
                , SvgAttr.stroke "black"
                , SvgAttr.strokeWidth "2px"
                ]
                []
            , questMarker
            ]
        ]


viewQuests : List Quest -> Html msg
viewQuests quests =
    div []
        (List.map viewQuest quests)
