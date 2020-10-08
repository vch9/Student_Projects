{ (* -*- tuareg -*- *)
  open Lexing
  open Error
  open Position
  open HopixParser

  let next_line_and f lexbuf  =
    Lexing.new_line lexbuf;
    f lexbuf

  let error lexbuf =
    error "during lexing" (lex_join lexbuf.lex_start_p lexbuf.lex_curr_p)

  let hexa_value d =
    let d = Char.code d in
    if d >= 97 then d - 87 else
    if d >= 65 then d - 55 else
    d - 48

  let hexa_to_char d u =
    let c = (16 * (hexa_value d) + (hexa_value u))
    in if c<32 then ' ' else Char.chr c (* unprintable *)

  let octal_to_char c d u =
    let c = 64 * (Char.code c - 48) +8 * (Char.code d - 48) + (Char.code u - 48)
    in if c<32 then ' ' else Char.chr c (* unprintable *)

  let escape_to_char c = match c with
  | 'n' -> '\010'
  | 'r' -> '\013'
  | 'b' -> '\008'
  | 't' -> '\009'
  | _ -> c

  let create_char s =
    let c = match (String.length s) with
    | 1 -> String.get s 0 (* printable *)
    | 4 -> octal_to_char (String.get s 1) (String.get s 2) (String.get s 3) (* \000 .. \255 *)
    | 5 -> hexa_to_char (String.get s 3) (String.get s 4) (* \0x__ *)
    | 2 -> escape_to_char (String.get s 1) (* '\n' '\r' .. *)
    | _ -> failwith "unknown char"
    in c

  let buffer = Buffer.create 256

  let store_buffer_char c = Buffer.add_char buffer c

  let reset_buffer () = Buffer.clear buffer

  let get_string () = Buffer.contents buffer

}

let newline = ('\010' | '\013' | "\013\010" )

let blank   = [' ' '\009' '\012']

let var_id = ['a'-'z']['A'-'Z' 'a'-'z' '0'-'9' '_']*

let constr_id = ['A'-'Z']['A'-'Z' 'a'-'z' '0'-'9' '_']*

let label_id = ['a'-'z']['A'-'Z' 'a'-'z' '0'-'9' '_']*

let type_con = ['a'-'z']['A'-'Z' 'a'-'z' '0'-'9' '_']*

let type_variable = '`'['a'-'z']['A'-'Z' 'a'-'z' '0'-'9' '_']*

let digit = ['0'-'9']

let atom = ['\x20' - '\x21'] (* Printable *)
| ['\x23' - '\x26'] (* Printable *)
| ['\x28' - '\x7f'] (* Printable *)
| '\\'['0'-'1']['0'-'9']['0'-'9']
| '\\''2'['0'-'5']['0'-'5']
| '\\''0''x'['0'-'9' 'a'-'f' 'A'-'F']['0'-'9' 'a'-'f' 'A'-'F']
| '\\''\\'
| '\\'('\\' | '\'' | 'n' | 't' | 'b' | 'r')

let char = ['\''](atom|'\x22')['\'']

let quote = ['\x22']


let int = '0''b'['0'-'1']+
| '0''o'['0'-'7']+
| '0''x'['0'-'9' 'a'-'f' 'A'-'F']+
| digit+
| '-'?digit+


rule token = parse
  (** Layout **)
  | newline         { next_line_and token lexbuf                                                }
  | blank+          { token lexbuf                                                              }
  | "/*"            { comment_lines lexbuf; token lexbuf                                        }
  | "//"            { comment lexbuf; token lexbuf                                              }

  (** BINOP **)
  | "-"             { MINUS                               }
  | "+"             { PLUS                                }
  | "*"             { TIMES                               }
  | "/"             { DIV                                 }
  | "&&"            { B_AND                               }
  | "||"            { B_OR                                }
  | "=?"            { B_EQUAL                             }
  | "<=?"           { LEQUAL                              }
  | ">=?"           { MEQUAL                              }
  | "<?"            { LESS                                }
  | ">?"            { MORE                                }
  | "<"             { LCHEV                               }
  | ">"             { RCHEV                               }

  (** KEY WORDS *)
  | "let"           { LET                                 }
  | "extern"        { EXTERN                              }
  | "while"         { WHILE                               }
  | "do"            { DO                                  }
  | "for"           { FOR                                 }
  | "in"            { IN                                  }
  | "to"            { TO                                  }
  | "switch"        { SWITCH                              }
  | "if"            { IF                                  }
  | "else"          { ELSE                                }
  | "ref"           { REF                                 }
  | "and"           { AND                                 }
  | "fun"           { FUN                                 }
  | "type"          { TYPE                                }

  (** PUNCTUATIONS **)
  | "{"             { OBRACE                              }
  | "}"             { CBRACE                              }
  | ","             { COMMA                               }
  | "("             { LPAR                                }
  | ")"             { RPAR                                }
  | ";"             { SEMICOLON                           }
  | "["             { LBRACKET                            }
  | "]"             { RBRACKET                            }
  | "."             { DOT                                 }

  (** OPERATORS **)
  | "!"             { EXCLA                               }
  | ":="            { ASSIGN                              }
  | "\\"            { BACKSLASH                           }
  | "&"             { AND                                 }
  | "|"             { OR                                  }
  | ":"             { COLON                               }
  | "_"             { UNDERSCORE                          }
  | "→"  | "->"     { RARROW                              }
  | "="             { EQUAL                               }


  (** ID **)
  | type_variable as s { TYPE_VAR s                                                                }
  | constr_id as s     { CONSTR_ID s                                                               }
  | var_id as s        { ID s                                                                      }

  (** LIT **)
  | int as i        { INT (Int64.of_string i)                                                   }
  | char as s       { CHAR (create_char (String.sub s 1 ((String.length s)-2)))                 }

  (** STRING **)
  | quote           { reset_buffer (); parse_string lexbuf; STRING (get_string ());             }

  | eof             { EOF                                                                       }
  (** Lexing error. *)
  | _               { error lexbuf "unexpected character."                                      }

  and comment_lines = parse
  | "/*"            { comment_lines lexbuf; comment_lines lexbuf  }
  | "*/"            { ()                                          }
  | eof             { error lexbuf "unterminated character."      }
  | _               { comment_lines lexbuf                        }

  and comment = parse
  | "\n"            { ()                                          }
  | eof             { () }
  | _               { comment lexbuf                              }

  and parse_string = parse
  | quote           {  ()                                                             }
  | atom as s       { store_buffer_char (create_char s); parse_string lexbuf          }
  | '\x27'          { store_buffer_char ('\x27'); parse_string lexbuf                 }
  | '\\''"'         { store_buffer_char ('\x22'); parse_string lexbuf                 }
  | _               { parse_string lexbuf                                             }
