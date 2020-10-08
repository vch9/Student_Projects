{ (* Emacs, open this with -*- tuareg -*- *)
  open Parser
}

rule token = parse
| ' ' {
  token lexbuf
}
| ['a'-'z']+ {
  ID (Lexing.lexeme lexbuf)
}
| ":=" {
  ASSIGN
}
| ";" {
  SEMICOLON
}
| ['0'-'9']+ as s {
  INT (int_of_string s)
}
| eof { EOF }
