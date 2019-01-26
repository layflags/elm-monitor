// Monitor Grammar
// ===============

// ----- Grammar -----

Monitor
  = ws value:value ws { return value; }

begin_list      = ws "[" ws
begin_record    = ws "{" ws
end_list        = ws "]" ws
end_record      = ws "}" ws
name_separator  = ws "=" ws
value_separator = ws "," ws
begin_tuple     = ws "(" ws
end_tuple       = ws ")" ws

ws "whitespace" = [ \t\n\r]*

// ----- Values -----

value
  = false
  / true
  / record
  / list
  / number
  / string
  / character
  / ctor_call_wrapped
  / ctor_call
  / ctor
  / internal
  / tuple
  / unit

false = "False" { return false; }
true  = "True"  { return true;  }
unit = "()" { return null; }


// ----- Ctor -----

ctor_call_wrapped
  = begin_tuple
    members:ctor_call
    end_tuple
    { return members; }

ctor_call
  = members:(
      head:ctor
      tail:(ws m:value { return m; })+
      {
        return [head].concat(tail)
      }
    )

ctor
  = [A-Z] [a-zA-Z0-9._]* { return "⟨" + text() + "⟩"; }

// ----- Tuple -----

tuple
  = begin_tuple
    members:(
      head:value
      tail:(value_separator m:value { return m; })+
      {
        return [head].concat(tail)
      }
    )
    end_tuple
    { return members; }


// ----- Records -----

record
  = begin_record
    members:(
      head:member
      tail:(value_separator m:member { return m; })*
      {
        var result = {};

        [head].concat(tail).forEach(function(element) {
          result[element.name] = element.value;
        });

        return result;
      }
    )?
    end_record
    { return members; }

member
  = name:key name_separator value:value {
      return { name: name, value: value };
    }

key
  = [a-z] [a-zA-Z0-9_]* { return text(); }

// ----- Lists -----

list
  = begin_list
    values:(
      head:value
      tail:(value_separator v:value { return v; })*
      { return [head].concat(tail); }
    )?
    end_list
    { return values !== null ? values : []; }

// ----- Numbers -----

number "number"
  = minus? int frac? exp? { return parseFloat(text()); }

decimal_point
  = "."

digit1_9
  = [1-9]

e
  = [eE]

exp
  = e (minus / plus)? DIGIT+

frac
  = decimal_point DIGIT+

int
  = zero / (digit1_9 DIGIT*)

minus
  = "-"

plus
  = "+"

zero
  = "0"

// ----- Strings -----

string "string"
  = quotation_mark chars:char* quotation_mark { return chars.join(""); }

character "character"
  = "'" c:char "'" { return c; }

internal "internal"
  = "<" [^>]+ ">" { return text(); }

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape
  = "\\"

quotation_mark
  = '"'

unescaped
  = [^\0-\x1F\x22\x5C]

// ----- Core ABNF Rules -----

// See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4234).
DIGIT  = [0-9]
HEXDIG = [0-9a-f]i
