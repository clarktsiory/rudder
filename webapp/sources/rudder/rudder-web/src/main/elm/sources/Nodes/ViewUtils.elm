module Nodes.ViewUtils exposing (..)

import Html exposing (..)
import Html.Attributes exposing (attribute, class, colspan, href, rowspan, style, title)
import Html.Events exposing (onClick, onInput)
import Json.Decode exposing (decodeValue)
import NaturalOrdering as N exposing (compare)
import Nodes.DataTypes exposing (..)
import Ui.DataTable exposing (..)


searchField : Node -> List String
searchField node =
    [ node.id.value
    , node.hostname
    ]


allColumns : List SortBy
allColumns =
    [ Hostname
    , Id

    -- , PolicyServer
    -- , Ram
    -- , AgentVersion
    -- , Software ""
    -- , NodeProperty "" False
    -- , PolicyMode
    -- , IpAddresses
    -- , MachineType
    -- , Kernel
    -- , Os
    -- , NodeCompliance
    -- , LastRun
    -- , InventoryDate
    ]


defaultColumns : List SortBy
defaultColumns =
    [ Hostname

    -- , PolicyMode
    -- , Os
    -- , NodeCompliance
    ]


getColumnTitle : SortBy -> String
getColumnTitle col =
    case col of
        Hostname ->
            "Hostname"

        Id ->
            "Node ID"



-- PolicyServer     -> "Policy server"
-- Ram              -> "RAM"
-- AgentVersion     -> "Agent version"
-- Software _       -> "Software"
-- NodeProperty _ _ -> "Property"
-- PolicyMode       -> "Policy mode"
-- IpAddresses      -> "IP addresses"
-- MachineType      -> "Machine type"
-- Kernel           -> "Kernel"
-- Os               -> "OS"
-- NodeCompliance   -> "Compliance"
-- LastRun          -> "Last run"
-- InventoryDate    -> "Inventory date"
