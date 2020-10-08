let parse input =
  let lexbuf = Lexing.from_string input in
  Parser.phrase Lexer.token lexbuf

let main =
  parse Sys.argv.(1)
