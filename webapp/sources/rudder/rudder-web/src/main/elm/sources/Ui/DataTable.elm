module Ui.DataTable exposing (ColumnName(..), Model, Msg, OutMsg(..), init, update, updateData, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra
import List.Nonempty as NonEmptyList
import Ordering
import UserManagement.View exposing (thClass)


type SortOrder
    = Asc
    | Desc


type ColumnName
    = ColumnName String


type alias Column line =
    { name : ColumnName, accessor : line -> String }


{-| TODO: <https://datatables.net/reference/type/DataTables.SearchOptions>
-}
type Filter
    = Substring String
    | NoFilter


type alias Config line =
    { columns : NonEmptyList.Nonempty (Column line)
    , sortBy : Maybe ColumnName
    , sortOrder : Maybe SortOrder
    , filter : Maybe Filter
    }


init : Config line -> List line -> Model line
init config data =
    { columns = config.columns
    , sortBy = config.sortBy |> Maybe.withDefault (NonEmptyList.head config.columns |> .name)
    , sortOrder = config.sortOrder |> Maybe.withDefault Asc
    , filter = config.filter |> Maybe.withDefault NoFilter
    , data = data
    }


type alias Model line =
    { columns : NonEmptyList.Nonempty (Column line)
    , sortBy : ColumnName
    , sortOrder : SortOrder
    , filter : Filter
    , data : List line
    }


type Msg
    = SortColumn ColumnName
    | RefreshMsg


type OutMsg
    = Refresh


updateData : List row -> Model row -> Model row
updateData rows model =
    { model | data = rows }
        |> applySort


update : Msg -> Model line -> ( Model line, Cmd Msg, Maybe OutMsg )
update msg model =
    case msg of
        SortColumn columnName ->
            ( model |> sortByColumnName columnName, Cmd.none, Nothing )

        RefreshMsg ->
            -- FIXME: disable button
            ( model, Cmd.none, Just Refresh )


sortByColumnName : ColumnName -> Model line -> Model line
sortByColumnName columnName model =
    model
        |> setSort columnName
        |> applySort


applySort : Model line -> Model line
applySort model =
    let
        maybeColumnAccessor =
            model.columns
                |> NonEmptyList.toList
                |> List.Extra.find (\{ name } -> name == model.sortBy)

        maybeSort =
            maybeColumnAccessor
                |> Maybe.map
                    (\{ accessor } ->
                        if model.sortOrder == Asc then
                            Ordering.byField accessor

                        else
                            Ordering.reverse (Ordering.byField accessor)
                    )
    in
    case maybeSort of
        Nothing ->
            model

        Just sort ->
            { model | data = List.sortWith sort model.data }


type alias Sort a =
    { a | sortBy : ColumnName, sortOrder : SortOrder }


setSort : ColumnName -> Sort a -> Sort a
setSort columnName sortState =
    let
        toggle =
            case sortState.sortOrder of
                Asc ->
                    Desc

                Desc ->
                    Asc
    in
    if columnName == sortState.sortBy then
        { sortState | sortOrder = toggle }

    else
        { sortState | sortBy = columnName, sortOrder = Asc }


filterSearch : Filter -> List String -> Bool
filterSearch filter searchFields =
    case filter of
        Substring filterString ->
            let
                -- Join all the fields into one string to simplify the search
                stringToCheck =
                    searchFields
                        |> String.join "|"
                        |> String.toLower

                searchString =
                    filterString
                        |> String.toLower
                        |> String.trim
            in
            String.contains searchString stringToCheck

        NoFilter ->
            True



-- Views


view : Model row -> Html Msg
view model =
    div [ class "table-container" ]
        [ button [ onClick RefreshMsg ] [ text "refresh" ]
        , table [ class "no-footer dataTable" ]
            [ thead [] [ nodesTableHeader model ]
            , tbody [] (buildNodesTable model)
            ]
        ]


nodesTableHeader : Model row -> Html Msg
nodesTableHeader model =
    tr [ class "head" ]
        (model.columns
            |> NonEmptyList.toList
            |> List.map (\column -> ( column.name, thClass model column.name ))
            |> List.map
                (\( ColumnName name, thClassValue ) ->
                    th
                        [ class thClassValue
                        , rowspan 1
                        , colspan 1
                        , onClick (SortColumn (ColumnName name))
                        ]
                        [ text name ]
                )
        )


thClass : Sort a -> ColumnName -> String
thClass { sortBy, sortOrder } columnName =
    if sortBy == columnName then
        case sortOrder of
            Asc ->
                "sorting_asc"

            Desc ->
                "sorting_desc"

    else
        "sorting"


buildNodesTable : Model row -> List (Html Msg)
buildNodesTable model =
    let
        rowTable : row -> Html msg
        rowTable n =
            tr []
                (model.columns
                    |> NonEmptyList.toList
                    |> List.map (\{ accessor } -> n |> accessor)
                    |> List.map (\s -> td [] [ text s ])
                )
    in
    if List.length model.data > 0 then
        List.map rowTable model.data

    else
        [ tr [] [ td [ class "empty", colspan 5 ] [ i [ class "fa fa-exclamation-triangle" ] [], text "No nodes match your filters." ] ] ]
