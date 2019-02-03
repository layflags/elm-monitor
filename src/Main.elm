port module Main exposing (main)

import Json.Encode as JE
import OutputParser
import Parser as P
import ParserFix as PF


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


okJson : JE.Value -> JE.Value
okJson value =
    JE.object [ ( "Ok", value ) ]


errJson : String -> JE.Value
errJson str =
    JE.object [ ( "Err", JE.string str ) ]


update : Msg -> () -> ( (), Cmd Msg )
update msg model =
    case msg of
        GotInput input ->
            case OutputParser.parse input of
                Ok data ->
                    ( (), sendParsedData <| okJson data )

                Err err ->
                    ( (), sendParsedData <| errJson <| PF.deadEndsToString err )


subscriptions : () -> Sub Msg
subscriptions _ =
    listenToInput GotInput
