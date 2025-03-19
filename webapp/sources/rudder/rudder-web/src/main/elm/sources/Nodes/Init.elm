module Nodes.Init exposing (..)

import Nodes.ApiCalls exposing (getNodeDetails)
import Nodes.DataTypes exposing (..)



-- import Ui.Datatable exposing (defaultTableFilters)


init : { contextPath : String, hasReadRights : Bool, policyMode : String } -> ( Model, Cmd Msg )
init flags =
    let
        initUi =
            UI flags.hasReadRights True False []

        -- TODO : Get columns list from browser cache
        initModel =
            Model flags.contextPath flags.policyMode [] initUi
    in
    ( initModel
    , getNodeDetails initModel
    )
