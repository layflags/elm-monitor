port module Main exposing (main)

import Json.Encode as JE


port sendParsedData : JE.Value -> Cmd Never


main : Program String () Never
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


init : String -> ( (), Cmd Never )
init input =
    case OutputParser.parse input of
        Ok data ->
            ( (), sendParsedData data )

        Err err ->
            let
                _ =
                    Debug.log "OMG!" err
            in
            ( (), Cmd.none )


update : Never -> () -> ( (), Cmd Never )
update msg model =
    ( model, Cmd.none )


subscriptios : () -> Sub Never
subscriptios _ =
    Sub.none
