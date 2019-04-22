module StringParserTest exposing (suite)

import Expect
import Parser
import ParserFix exposing (deadEndsToString)
import StringParser exposing (string)
import Test exposing (..)


quoted : String -> String
quoted str =
    "\"" ++ str ++ "\""


suite : Test
suite =
    describe "parse"
        [ test "works with strings that contain double quotes" <|
            \() ->
                case Parser.run string <| quoted "\\\"" of
                    Ok result ->
                        result |> Expect.equal "\""

                    Err err ->
                        Expect.fail <| deadEndsToString err
        , test "works with strings that contain slashes" <|
            \() ->
                case Parser.run string <| quoted "\\\\" of
                    Ok result ->
                        result |> Expect.equal "\\"

                    Err err ->
                        Expect.fail <| deadEndsToString err
        ]
