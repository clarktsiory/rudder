module  JsonEncoder exposing (..)

import DataTypes exposing (..)
import Json.Encode exposing (..)

encodeSchedule : Schedule -> Value
encodeSchedule schedule =
  let
   override = case schedule.overrides of
     Just o  -> o
     Nothing -> False
  in
    object (
      [ ( "overrides"   , bool override            )
      , ( "interval"    , int schedule.interval    )
      , ( "startHour"   , int schedule.startHour   )
      , ( "startMinute" , int schedule.startMinute )
      , ( "splayHour"   , int schedule.splayHour   )
      , ( "splayMinute" , int schedule.splayMinute )
      ]
    )