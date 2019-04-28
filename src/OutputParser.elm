module OutputParser exposing (parse)

import Char
import Json.Encode as JE
import Parser exposing (..)
import Set
import StringParser as SP


parse : String -> Result (List DeadEnd) JE.Value
parse =
    Parser.run parser



-- STRING


string : Parser JE.Value
string =
    map JE.string SP.string


char : Parser JE.Value
char =
    succeed JE.string
        |. symbol "'"
        |= (getChompedString <| chompWhile ((/=) '\''))
        |. symbol "'"



-- BOOL


bool : Parser JE.Value
bool =
    oneOf
        [ keyword "True" |> map (\_ -> JE.bool True)
        , keyword "False" |> map (\_ -> JE.bool False)
        ]



-- NUMBER


num : Parser Float
num =
    number
        { int = Just toFloat
        , hex = Nothing
        , octal = Nothing
        , binary = Nothing
        , float = Just identity
        }


float : Parser JE.Value
float =
    oneOf
        [ succeed negate
            |. symbol "-"
            |= num
        , num
        ]
        |> map JE.float



-- UNIT


unit : Parser JE.Value
unit =
    symbol "()" |> map (\_ -> JE.null)



-- LIST


list : Parser JE.Value
list =
    sequence
        { start = "["
        , separator = ","
        , end = "]"
        , spaces = spaces
        , item = value
        , trailing = Forbidden
        }
        |> map (JE.list identity)



-- OBJECT


key : Parser String
key =
    variable
        { start = \c -> Char.isLower c || Char.isDigit c
        , inner = \c -> Char.isAlphaNum c || c == '_'
        , reserved = Set.empty
        }


keyValue : Parser ( String, JE.Value )
keyValue =
    succeed Tuple.pair
        |= key
        |. spaces
        |. symbol "="
        |. spaces
        |= value


record : Parser JE.Value
record =
    sequence
        { start = "{"
        , separator = ","
        , end = "}"
        , spaces = spaces
        , item = keyValue
        , trailing = Forbidden
        }
        |> map JE.object



-- INTERNALS


internals : Parser JE.Value
internals =
    map JE.string <|
        getChompedString <|
            succeed ()
                |. symbol "<"
                |. chompWhile ((/=) '>')
                |. symbol ">"



-- TUPLES


tuple : Parser JE.Value
tuple =
    succeed
        (\first second rest ->
            JE.list identity (first :: second :: rest)
        )
        |. symbol "("
        |. spaces
        |= value
        |. spaces
        |. symbol ","
        |. spaces
        |= value
        |. spaces
        |= loop [] tupleRestHelp
        |. symbol ")"


tupleRestHelp : List JE.Value -> Parser (Step (List JE.Value) (List JE.Value))
tupleRestHelp state =
    oneOf
        [ succeed
            (\call -> Loop (call :: state))
            |. symbol ","
            |. spaces
            |= value
        , succeed (Done (List.reverse state))
        ]



-- UNION


ctor : Parser JE.Value
ctor =
    map (JE.string << formatCtor) <|
        variable
            { start = Char.isUpper
            , inner = \c -> Char.isAlphaNum c || c == '_' || c == '.'
            , reserved = Set.empty
            }


formatCtor : String -> String
formatCtor str =
    "⟨" ++ str ++ "⟩"


ctorArgsHelp : List JE.Value -> Parser (Step (List JE.Value) (List JE.Value))
ctorArgsHelp state =
    succeed identity
        |. spaces
        |= oneOf
            [ succeed
                (\call -> Loop (call :: state))
                |= value
            , succeed
                (\call -> Loop (call :: state))
                |. symbol "("
                |= lazy (\_ -> union)
                |. symbol ")"
            , succeed (Done (List.reverse state))
            ]


type NonEmptyList a
    = NonEmptyList a (List a)


{-| turn ctor only to String, ctor with args to array
-}
nonEmptyListToValue : NonEmptyList JE.Value -> JE.Value
nonEmptyListToValue nonEmptyList =
    case nonEmptyList of
        NonEmptyList head [] ->
            head

        NonEmptyList head tail ->
            JE.list identity (head :: tail)


ctorWithArgs : Parser (NonEmptyList JE.Value)
ctorWithArgs =
    succeed NonEmptyList
        |= ctor
        |= loop [] ctorArgsHelp


union : Parser JE.Value
union =
    map nonEmptyListToValue ctorWithArgs



-- VALUE


value : Parser JE.Value
value =
    oneOf
        [ bool
        , unit
        , char
        , string
        , internals
        , lazy (\() -> record)
        , lazy (\() -> list)
        , backtrackable <| lazy (\() -> tuple)
        , lazy (\() -> union)
        , float
        ]



-- FINAL PARSER


parser : Parser JE.Value
parser =
    succeed identity
        |. spaces
        |= value
        |. spaces
