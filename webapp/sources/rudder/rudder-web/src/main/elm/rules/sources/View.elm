module View exposing (..)

import DataTypes exposing (..)
import Html exposing (Html, button, div, i, span, text, h1, h3, ul, li, input, a, table, thead, tbody, tr, th)
import Html.Attributes exposing (class, type_, placeholder, value, colspan, rowspan, style, tabindex)
import Html.Events exposing (onClick, onInput)
import List
import String
import ApiCalls exposing (..)
import ViewRulesTable exposing (..)
import ViewRuleDetails exposing (..)
import ViewCategoryDetails exposing (..)
import ViewUtils exposing (..)


view : Model -> Html Msg
view model =
  let
    allMissingCategoriesId = List.map .id (getAllMissingCats model.rulesTree)
    ruleTreeElem : Rule -> Html Msg
    ruleTreeElem item =
      let
        (classDisabled, badgeDisabled) = if item.enabled /= True then
            (" item-disabled", span[ class "badge-disabled"][])
          else
            ("", text "")
        classFocus =
          case model.mode of
            RuleForm rDetails ->
              if (rDetails.rule.id.value == item.id.value) then " focused " else ""
            _ -> ""
      in
        li [class "jstree-node jstree-leaf"]
        [ i[class "jstree-icon jstree-ocl"][]
        , a[class ("jstree-anchor"++classDisabled++classFocus), onClick (OpenRuleDetails item.id True)]
          [ i [class "jstree-icon jstree-themeicon fa fa-sitemap jstree-themeicon-custom"][]
          , span [class "treeGroupName tooltipable"]
            [ badgePolicyMode model.policyMode item.policyMode
            , text item.name
            , badgeDisabled
            , buildTagsTree item.tags
            ]
          ]
        ]

    ruleTreeCategory : (Category Rule) -> Maybe (Html Msg)
    ruleTreeCategory item =
      let
        missingCat = getSubElems item
          |> List.filter (\c -> c.id == missingCategoryId)
          |> List.sortBy .name
          |> List.filterMap ruleTreeCategory

        categories = getSubElems item
          |> List.filter (\c -> c.id /= missingCategoryId)
          |> List.sortBy .name
          |> List.filterMap ruleTreeCategory

        rules = item.elems
          |> List.filter (\r -> filterSearch model.ui.ruleFilters.treeFilters.filter (searchFieldRules r model))
          |> List.sortBy .name
          |> List.map ruleTreeElem

        childsList  = ul[class "jstree-children"] (List.concat [categories, rules, missingCat] )
        mainMissingCat =
          if(item.id == missingCategoryId) then
            " main-missing-cat "
          else
            ""
        icons =
          if(item.id == missingCategoryId) then
            " fas fa-exclamation-triangle " ++ mainMissingCat
          else
            " fa fa-folder "
        classFocus =
          case model.mode of
            CategoryForm cDetails ->
              if (cDetails.category.id == item.id) then " focused " else ""
            _ -> ""
        missingCatClass = if(List.member item.id allMissingCategoriesId) then " missing-cat " else ""
        treeItem =
          if item.id /= "rootRuleCategory" then
            if (String.isEmpty model.ui.ruleFilters.treeFilters.filter) || ((List.length rules > 0) || (List.length categories > 0)) then
              Just (
                li[class ("jstree-node" ++ foldedClass model.ui.ruleFilters.treeFilters item.id)]
                [ i [class "jstree-icon jstree-ocl", onClick (UpdateRuleFilters (foldUnfoldCategory model.ui.ruleFilters item.id))][]
                , a [class ("jstree-anchor" ++ classFocus), onClick (OpenCategoryDetails item.id True)]
                  [ i [class ("jstree-icon jstree-themeicon jstree-themeicon-custom" ++ icons)][]
                  , span [class ("treeGroupCategoryName tooltipable " ++ missingCatClass ++ mainMissingCat)][text item.name]
                  ]
                , childsList
                ]
              )
            else
              Nothing
          else
            Just childsList
      in
        treeItem

    templateMain = case model.mode of
      Loading -> text "loading"
      RuleTable   ->
        let
          ruleFilters = model.ui.ruleFilters
        in
          div [class "main-table"]
          [ div [class "table-container"]
            [ table [ class "no-footer dataTable"]
              [ thead []
                [ tr [class "head"]
                  [ th [ class (thClass model.ui.ruleFilters.tableFilters Name) , rowspan 1, colspan 1
                       , onClick (UpdateRuleFilters (sortTable ruleFilters Name))
                       ] [ text "Name" ]
                  , th [ class (thClass model.ui.ruleFilters.tableFilters Parent) , rowspan 1, colspan 1
                       , onClick (UpdateRuleFilters (sortTable ruleFilters Parent))
                       ] [ text "Category" ]
                  , th [ class (thClass model.ui.ruleFilters.tableFilters Status) , rowspan 1, colspan 1
                       , onClick (UpdateRuleFilters (sortTable ruleFilters Status))
                       ] [ text "Status" ]
                  , th [ class (thClass model.ui.ruleFilters.tableFilters Compliance) , rowspan 1, colspan 1
                       , onClick (UpdateRuleFilters (sortTable ruleFilters Compliance))
                       ] [ text "Compliance" ]
                  , th [ class (thClass model.ui.ruleFilters.tableFilters RuleChanges) , rowspan 1, colspan 1
                       , onClick (UpdateRuleFilters (sortTable ruleFilters RuleChanges))
                       ] [ text "Changes" ]
                  ]
                ]
              , tbody [] (buildRulesTable model)
              ]
            ]
          ]

      RuleForm details ->
        (editionTemplate model details)

      CategoryForm details ->
        (editionTemplateCat model details)

    modal = case model.ui.modal of
      NoModal -> text ""
      DeletionValidation rule ->
        div [ tabindex -1, class "modal fade in", style "z-index" "1050", style "display" "block" ]
        [ div [ class "modal-dialog" ] [
            div [ class "modal-content" ] [
              div [ class "modal-header ng-scope" ] [
                h3 [ class "modal-title" ] [ text "Delete Rule"]
              ]
            , div [ class "modal-body" ] [
                text ("Are you sure you want to Delete rule '"++ rule.name ++"'?")
              ]
            , div [ class "modal-footer" ] [
                button [ class "btn btn-default", onClick (ClosePopup Ignore) ]
                [ text "Cancel " ]
              , button [ class "btn btn-danger", onClick (ClosePopup (CallApi (deleteRule rule))) ]
                [ text "Delete "
                , i [ class "fa fa-times-circle" ] []
                ]
              ]
            ]
          ]
        ]
      DeactivationValidation rule ->
        let
          txtDisable = if rule.enabled then "Disable" else "Enable"
        in
          div [ tabindex -1, class "modal fade in", style "z-index" "1050", style "display" "block" ]
          [ div [ class "modal-dialog" ] [
              div [ class "modal-content" ]  [
                div [ class "modal-header ng-scope" ] [
                  h3 [ class "modal-title" ] [ text (txtDisable ++" Rule")]
                ]
              , div [ class "modal-body" ] [
                  text ("Are you sure you want to "++ String.toLower txtDisable ++" rule '"++ rule.name ++"'?")
                ]
              , div [ class "modal-footer" ] [
                  button [ class "btn btn-primary btn-outline pull-left", onClick (ClosePopup Ignore) ]
                  [ text "Cancel "
                  , i [ class "fa fa-arrow-left" ] []
                  ]
                , button [ class "btn btn-primary", onClick (ClosePopup DisableRule) ]
                  [ text (txtDisable ++ " ")
                  , i [ class "fa fa-ban" ] []
                  ]
                ]
              ]
            ]
          ]
      DeletionValidationCat category ->
        div [ tabindex -1, class "modal fade in", style "z-index" "1050", style "display" "block" ]
         [ div [ class "modal-dialog" ] [
             div [ class "modal-content" ] [
               div [ class "modal-header ng-scope" ] [
                 h3 [ class "modal-title" ] [ text "Delete category"]
               ]
             , div [ class "modal-body" ] [
                 text ("Are you sure you want to delete category '"++ category.name ++"'?")
               ]
             , div [ class "modal-footer" ] [
                 button [ class "btn btn-default", onClick (ClosePopup Ignore) ]
                 [ text "Cancel " ]
               , button [ class "btn btn-danger", onClick (ClosePopup (CallApi (deleteCategory category))) ]
                 [ text "Delete "
                 , i [ class "fa fa-times-circle" ] []
                 ]
               ]
             ]
           ]
         ]
  in
    div [class "rudder-template"]
    [ div [class "template-sidebar sidebar-left"]
      [ div [class "sidebar-header"]
        [ div [class "header-title"]
          [ h1[]
            [ span[][text "Rules"]
            ]
          , ( if model.ui.hasWriteRights then
              div [class "header-buttons"]
              [ button [class "btn btn-default", type_ "button", onClick (GenerateId (\s -> NewCategory s      ))][text "Add Category"]
              , button [class "btn btn-success", type_ "button", onClick (GenerateId (\s -> NewRule (RuleId s) ))][text "Create", i[class "fa fa-plus-circle"][]]
              ]
            else
              text ""
            )
          ]
        , div [class "header-filter"]
          [ div [class "input-group"]
            [ div [class "input-group-btn"]
              [ button [class "btn btn-default", type_ "button"][span [class "fa fa-folder fa-folder-open"][]]
              ]
            , input[type_ "text", value model.ui.ruleFilters.treeFilters.filter ,placeholder "Filter", class "form-control", onInput (\s ->
              let
                ruleFilters = model.ui.ruleFilters
                treeFilters = ruleFilters.treeFilters
              in
                UpdateRuleFilters {ruleFilters | treeFilters = {treeFilters | filter = s}}
            )][]
            , div [class "input-group-btn"]
              [ button [class "btn btn-default", type_ "button", onClick (
                let
                  ruleFilters = model.ui.ruleFilters
                  treeFilters = ruleFilters.treeFilters
                in
                  UpdateRuleFilters {ruleFilters | treeFilters = {treeFilters | filter = ""}}
                )] [span [class "fa fa-times"][]]
              ]
            ]
          ]
        ]
      , div [class "sidebar-body"]
        [ div [class "sidebar-list"][(
          if model.ui.loadingRules then
            generateLoadingList
          else
            div [class "jstree jstree-default"]
            [ ul[class "jstree-container-ul jstree-children"]
              [(case ruleTreeCategory model.rulesTree of
                Just html -> html
                Nothing   -> div [class "alert alert-warning"]
                  [ i [class "fa fa-exclamation-triangle"][]
                  , text  "No rules match your filter."
                  ]
              )]
            ]
          )]
        ]
     ]
    , div [class "template-main"]
      [ templateMain ]
    , modal
    ]