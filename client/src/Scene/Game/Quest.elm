module Scene.Game.Quest exposing (Msg(..), update, view, viewQuest, viewQuestDetails, viewQuestDetailsModal, viewQuests, viewTeamDetails)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Bootstrap.Table as Table
import Bootstrap.Utilities.Spacing as Spacing
import Data.Quest exposing (Quest, QuestScene)
import Data.Team exposing (Team)
import Data.TeamHistory exposing (TeamHistory)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Scene.Game.Player as Player
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
                    , SvgAttr.cy "55"
                    , SvgAttr.r (toString (size / 4))
                    , SvgAttr.fill "#B8860B"
                    , SvgAttr.stroke "black"
                    , SvgAttr.strokeWidth "1.5px"
                    ]
                    []

            else
                Svg.circle
                    [ SvgAttr.cx (toString (size - (size / 12)))
                    , SvgAttr.cy "55"
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
            , SvgAttr.height "70"
            ]
            [ Svg.circle
                [ SvgAttr.cx (toString ((size / 2) + 1.25))
                , SvgAttr.cy "35"
                , SvgAttr.r halfSizeStr
                , SvgAttr.fill questColor
                ]
                []
            , Svg.text_
                [ SvgAttr.x "16"
                , SvgAttr.y "47"
                , SvgAttr.fontSize "35"
                , SvgAttr.fill "black"
                ]
                [ Svg.text (toString quest.team.num_players_required) ]
            , Svg.circle
                [ SvgAttr.cx (toString ((size / 2) + 1.25))
                , SvgAttr.cy "35"
                , SvgAttr.r halfSizeStr
                , SvgAttr.fill "none"
                , SvgAttr.stroke "black"
                , SvgAttr.strokeWidth "2px"
                ]
                []
            , Svg.textPath
                [ SvgAttr.fill "black"
                , SvgAttr.stroke "#000"
                , SvgAttr.strokeWidth "3px"
                , SvgAttr.strokeLinejoin "round"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.d "M7,43 C9,1 56,-2 58,43"
                , SvgAttr.xlinkHref "#curve"
                ]
                [ Svg.text "hello world" ]
            , questMarker
            ]
        ]


viewTeamDetails : String -> Team -> String -> Tab.Item Msg
viewTeamDetails label team king =
    let
        viewVote ( player, vote ) =
            let
                king_crown =
                    if player == king then
                        span [] [ Player.viewModifier Player.King, text " " ]

                    else
                        text ""

                formattedName =
                    if List.member player team.players then
                        span [] [ text player, text " ", Player.viewModifier Player.IsOnQuest ]

                    else
                        span [] [ text player ]

                formattedVote =
                    case vote of
                        "accept" ->
                            span [ style [ ( "color", "green" ) ] ] [ text vote ]

                        "reject" ->
                            span [ style [ ( "color", "red" ) ] ] [ text vote ]

                        _ ->
                            text vote
            in
            Table.tr []
                [ Table.td [] [ king_crown, formattedName ]
                , Table.td [] [ formattedVote ]
                ]
    in
    Tab.item
        { id = label
        , link = Tab.link [] [ text label ]
        , pane =
            Tab.pane [ Spacing.mt3 ]
                [ Table.table
                    { options = [ Table.striped, Table.hover, Table.small ]
                    , thead =
                        Table.simpleThead
                            [ Table.th [] [ text "Player" ]
                            , Table.th [] [ text "Vote" ]
                            ]
                    , tbody =
                        Table.tbody []
                            (List.map (\vote -> viewVote vote) team.votes)
                    }
                ]
        }


viewAllTeamHistoryDetails : QuestScene -> Team -> List TeamHistory -> Html Msg
viewAllTeamHistoryDetails scene team teamHistory =
    let
        indexedTeamHistory =
            List.reverse (List.indexedMap (\index team -> ( index, team )) (List.reverse teamHistory))
    in
    Tab.config QuestTab
        |> Tab.items
            (List.map (\( index, history ) -> viewTeamDetails ("Team " ++ toString (index + 1)) history.team history.king) indexedTeamHistory)
        |> Tab.view scene.tabState


viewQuestDetails : QuestScene -> Quest -> Html Msg
viewQuestDetails scene quest =
    let
        questInfo =
            if quest.state == "uncompleted" then
                text ""

            else
                div []
                    [ p [] [ text ("State: " ++ quest.state) ]
                    , p [] [ text ("Quest Card Players: " ++ toString quest.quest_card_players) ]
                    , p [] [ text ("Quest Cards: " ++ toString quest.quest_cards) ]
                    ]
    in
    div []
        [ questInfo
        , viewAllTeamHistoryDetails scene quest.team quest.team_history
        ]


viewQuestDetailsModal : QuestScene -> List Quest -> Html Msg
viewQuestDetailsModal scene quests =
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
    div [] ([ viewQuestDetailsModal scene quests ] ++ List.map (viewQuest scene) quests)


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
