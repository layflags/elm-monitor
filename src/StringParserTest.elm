module StringParserTest exposing (suite)

import Expect
import Parser
import ParserFix exposing (deadEndsToString)
import StringParser exposing (string)
import Test exposing (..)


suite : Test
suite =
    describe "parse"
        [ test "works with strings that contain double quotes" <|
            \() ->
                case Parser.run string "\"\\\"\"" of
                    Ok result ->
                        result |> Expect.equal "\""

                    Err err ->
                        Expect.fail <| deadEndsToString err
        ]
