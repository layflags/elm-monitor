port module Main exposing (main)

import Json.Encode as JE
import OutputParser


port sendParsedData : JE.Value -> Cmd msg


port listenToInput : (String -> msg) -> Sub msg


type Msg
    = GotInput String


main : Program () () Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( (), Cmd Msg )
init _ =
    ( (), Cmd.none )


update : Msg -> () -> ( (), Cmd Msg )
update msg model =
    case msg of
        GotInput input ->
            case OutputParser.parse input of
                Ok data ->
                    ( (), sendParsedData data )

                Err err ->
                    --let
                    --_ =
                    --Debug.log "OMG!" err
                    --in
                    ( (), Cmd.none )


subscriptions : () -> Sub Msg
subscriptions _ =
    listenToInput GotInput
