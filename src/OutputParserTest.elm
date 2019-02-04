module OutputParserTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Encode as JE
import OutputParser exposing (parse)
import Test exposing (..)


suite : Test
suite =
    describe "parse"
        [ test "should parse a string" <|
            \() ->
                parse "\"Peter\""
                    |> Expect.equal (Ok (JE.string "Peter"))
        , let
            recordStr =
                """
                (NoOp "peter",
                { fragment = Nothing
                , host = "localhost"
                , port_ = Just 8080
                , protocol = Http
                , peter = False
                , num = 4.5
                , int = 1
                , list = [1, 2, 3]
                , unit = ()
                , internal = <secret>
                , tuple = (1, "assi", [1, 2, 3])
                , union = Peter 3 True (Just 3)
                }
                )
                """

            json =
                JE.list identity
                    [ JE.list identity [ JE.string "⟨NoOp⟩", JE.string "peter" ]
                    , JE.object
                        [ ( "fragment", JE.string "⟨Nothing⟩" )
                        , ( "host", JE.string "localhost" )
                        , ( "port_", JE.list identity [ JE.string "⟨Just⟩", JE.int 8080 ] )
                        , ( "protocol", JE.string "⟨Http⟩" )
                        , ( "peter", JE.bool False )
                        , ( "num", JE.float 4.5 )
                        , ( "int", JE.int 1 )
                        , ( "list", JE.list JE.int (List.range 1 3) )
                        , ( "unit", JE.null )
                        , ( "internal", JE.string "<secret>" )
                        , ( "tuple"
                          , JE.list identity
                                [ JE.int 1
                                , JE.string "assi"
                                , JE.list JE.int (List.range 1 3)
                                ]
                          )
                        , ( "union"
                          , JE.list identity
                                [ JE.string "⟨Peter⟩"
                                , JE.int 3
                                , JE.bool True
                                , JE.list identity
                                    [ JE.string "⟨Just⟩"
                                    , JE.int 3
                                    ]
                                ]
                          )
                        ]
                    ]
          in
          test "should parse a big record" <|
            \() ->
                parse recordStr
                    |> Expect.equal (Ok json)
        , test "should parse some data" <|
            \() ->
                let
                    data =
                        """
(GotHereAndNow (Zone 60 [],Posix 1549222093485),{ here = Zone 60 [], key = <function>, now = Posix 1549222093485, page = Home { url = { fragment = Nothing, host = "localhost", path = "/", port_ = Just 8080, protocol = Http, query = Nothing } } })
                      """
                in
                case parse data of
                    Ok _ ->
                        Expect.pass

                    Err err ->
                        let
                            _ =
                                Debug.log "err" err
                        in
                        Expect.fail "Couldn't parse"
        , test "can parse chars as well" <|
            \() ->
                parse "'a'"
                    |> Expect.equal (Ok <| JE.string "a")
        , test "chars can also be unicode points" <|
            \() ->
                parse "'🙂'"
                    |> Expect.equal (Ok <| JE.string "🙂")
        ]
