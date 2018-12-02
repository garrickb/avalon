module Scene.Game.Quest exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Bootstrap.Utilities.Spacing as Spacing
import Data.Quest exposing (Quest, QuestScene)
import Data.Team exposing (Team)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Svg
import Svg.Attributes as SvgAttr


viewQuest : QuestScene -> Quest -> Html Msg
viewQuest scene quest =
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
    Button.button
        [ Button.roleLink
        , Button.attrs [ Spacing.ml1, onClick (SelectQuest (Just quest)), style [ ( "padding", "0px" ) ] ]
        ]
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


viewTeamDetails : String -> Team -> Tab.Item Msg
viewTeamDetails label team =
    Tab.item
        { id = "pillItem1"
        , link = Tab.link [] [ text label ]
        , pane =
            Tab.pane [ Spacing.mt3 ]
                [ p [] [ text ("Num players required: " ++ toString team.num_players_required) ]
                , p [] [ text ("Players: " ++ toString team.players) ]
                , p [] [ text ("Votes: " ++ toString team.votes) ]
                ]
        }


viewAllTeamDetails : QuestScene -> Team -> List Team -> Html Msg
viewAllTeamDetails scene team teamHistory =
    Tab.config QuestTab
        |> Tab.pills
        |> Tab.items
            ([ viewTeamDetails "Current" team ] ++ List.map (viewTeamDetails "History") teamHistory)
        |> Tab.view scene.tabState


viewQuestDetails : QuestScene -> Quest -> Html Msg
viewQuestDetails scene quest =
    let
        questInfo =
            div []
                [ p [] [ text ("Active: " ++ toString quest.active) ]
                , p [] [ text ("Num Fails required: " ++ toString quest.num_fails_required) ]
                , p [] [ text ("State: " ++ quest.state) ]
                , p [] [ text ("Quest Card Players: " ++ toString quest.quest_card_players) ]
                , p [] [ text ("Quest Cards: " ++ toString quest.quest_cards) ]
                ]
    in
    div []
        [ questInfo
        , viewAllTeamDetails scene quest.team quest.team_history
        ]


viewQuestDetailsModal : QuestScene -> Html Msg
viewQuestDetailsModal scene =
    let
        modalVisibility =
            case scene.selectedQuest of
                Nothing ->
                    Modal.hidden

                Just quest ->
                    Modal.shown

        questDetails =
            case scene.selectedQuest of
                Just quest ->
                    viewQuestDetails scene quest

                Nothing ->
                    text "No quest selected."
    in
    Modal.config (SelectQuest Nothing)
        |> Modal.small
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text "Quest Details" ]
        |> Modal.body [] [ p [] [ questDetails ] ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick (SelectQuest Nothing) ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view modalVisibility


viewQuests : QuestScene -> List Quest -> Html Msg
viewQuests scene quests =
    div [] ([ viewQuestDetailsModal scene ] ++ List.map (viewQuest scene) quests)


view : QuestScene -> List Quest -> Html Msg
view scene quests =
    viewQuests scene quests


type Msg
    = QuestTab Tab.State
    | SelectQuest (Maybe Quest)


update : Msg -> QuestScene -> ( QuestScene, Cmd Msg )
update msg scene =
    case msg of
        QuestTab state ->
            { scene | tabState = state } ! []

        SelectQuest maybeQuest ->
            { scene | selectedQuest = maybeQuest } ! []
