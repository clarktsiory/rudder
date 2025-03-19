module Ui.Datatable exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, div, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, style)



-- TODO : Pagination, export buttons, better columns edit
--
-- COMPLIANCE TABLES
--


type alias Category a =
    { id : String
    , name : String
    , description : String
    , subElems : SubCategories a
    , elems : List a
    }


type SubCategories a
    = SubCategories (List (Category a))


getAllElems : Category a -> List a
getAllElems category =
    let
        subElems =
            case category.subElems of
                SubCategories l ->
                    l
    in
    List.append category.elems (List.concatMap getAllElems subElems)


getSubElems : Category a -> List (Category a)
getSubElems cat =
    case cat.subElems of
        SubCategories subs ->
            subs


getAllCats : Category a -> List (Category a)
getAllCats category =
    let
        subElems =
            case category.subElems of
                SubCategories l ->
                    l
    in
    category :: List.concatMap getAllCats subElems


emptyCategory : Category a
emptyCategory =
    Category "" "" "" (SubCategories []) []



---
--- LOADING ANIMATION
---


generateLoadingTable : Bool -> Int -> Html msg
generateLoadingTable withFilter nbColumns =
    let
        nbRows =
            20

        filter =
            if withFilter then
                div [ class "dataTables_wrapper_top table-filter" ]
                    [ div [ class "form-group" ]
                        [ span [] []
                        ]
                    ]

            else
                text ""
    in
    div [ class "table-container skeleton-loading" ]
        [ filter
        , table [ class "dataTable" ]
            [ thead []
                [ tr [ class "head" ]
                    (List.repeat nbColumns (th [] [ span [] [] ]))
                ]
            , tbody []
                (List.repeat nbRows
                    (tr [] (List.repeat nbColumns (td [] [ span [] [] ])))
                )
            ]
        ]
