module DataTables exposing (..)

import Browser
import Html exposing (Html)
import List.Nonempty as NonEmptyList
import Task exposing (Task)
import Ui.DataTable as DataTable


type alias Row =
    { id : String, hostname : String }


type alias Model =
    { data : List Row
    , table : DataTable.Model Row
    }


data =
    [ { id = "root", hostname = "hostname" }
    , { id = "relay", hostname = "relay123" }
    ]


data2 =
    [ { id = "root", hostname = "hostname" }
    , { id = "relay", hostname = "relay123" }
    , { id = "relay2", hostname = "relay123" }
    , { id = "relay3", hostname = "relay123" }
    , { id = "relay4", hostname = "relay123" }
    , { id = "relay5", hostname = "relay123" }
    ]


initModel : Model
initModel =
    { data = data
    , table =
        DataTable.init
            { columns = NonEmptyList.Nonempty { name = DataTable.ColumnName "Hostname", accessor = .hostname } [ { name = DataTable.ColumnName "Id", accessor = .id } ]
            , sortBy = Nothing
            , sortOrder = Nothing
            , filter = Nothing
            }
            data
    }


type Msg
    = DataTableMsg DataTable.Msg
    | LoadData
    | DataLoaded (List Row)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataTableMsg tableMsg ->
            let
                ( updatedModel, cmd, outMsg ) =
                    DataTable.update tableMsg model.table

                myCmd =
                    case outMsg of
                        Just DataTable.Refresh ->
                            loadData

                        Nothing ->
                            Cmd.none
            in
            ( { model | table = updatedModel }, Cmd.batch [ Cmd.map DataTableMsg cmd, myCmd ] )

        LoadData ->
            ( model, dataLoaded )

        DataLoaded rows ->
            ( { model | data = rows, table = DataTable.updateData rows model.table }, Cmd.none )


view : Model -> Html Msg
view m =
    DataTable.view m.table |> Html.map DataTableMsg


msgToCmd : msg -> Cmd msg
msgToCmd =
    Task.succeed >> Task.perform identity


loadData : Cmd Msg
loadData =
    msgToCmd LoadData


dataLoaded : Cmd Msg
dataLoaded =
    msgToCmd (DataLoaded data2)


main =
    Browser.element
        { init = \() -> ( initModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
