module Nodes exposing (..)

import Browser
import Http
import Nodes.DataTypes exposing (..)
import Nodes.Init exposing (init)
import Nodes.View exposing (view)
import Result exposing (..)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ ui } as model) =
    case msg of
        Ignore ->
            ( model, Cmd.none )

        Copy _ ->
            ( model, Cmd.none )

        CallApi call ->
            ( model, call model )

        GetNodes (Ok nodes) ->
            ( { model | nodes = nodes, ui = { ui | loading = False } }, Cmd.none )

        GetNodes (Err err) ->
            processApiError "Could not get nodes" err model

        UpdateUI newUi ->
            ( { model | ui = newUi }, Cmd.none )


processApiError : String -> Http.Error -> Model -> ( Model, Cmd Msg )
processApiError apiName err model =
    let
        message =
            case err of
                Http.BadUrl url ->
                    "The URL " ++ url ++ " was invalid"

                Http.Timeout ->
                    "Unable to reach the server, try again"

                Http.NetworkError ->
                    "Unable to reach the server, check your network connection"

                Http.BadStatus 500 ->
                    "The server had a problem, try again later"

                Http.BadStatus 400 ->
                    "Verify your information and try again"

                Http.BadStatus _ ->
                    "Unknown error"

                Http.BadBody errorMessage ->
                    errorMessage
    in
    ( model, Cmd.none )
