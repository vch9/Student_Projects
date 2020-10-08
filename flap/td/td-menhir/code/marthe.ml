open AST

let rec interactive_loop () =
  welcome_message ();
  let rec loop () =
    begin try
      read () |> eval |> print
    with exn ->
      Printf.printf "Error: %s\n%!" (Printexc.to_string exn)
    end;
    loop ()
  in
  loop ()

and welcome_message () =
  Printf.printf "
  ====================================================\n
   Welcome to the incredible Marthe interactive loop! \n
  ====================================================\n
"

and read () =
  invite (); input_line stdin |> parse

and invite () =
  Printf.printf "> %!"

and parse input =
  let lexbuf = Lexing.from_string input in
  Parser.phrase Lexer.token lexbuf

and print e =
  Printf.printf ":- %d\n%!" e

and eval e =
let rec aux e env = match e with
  | Id id -> List.assoc id env
  | LInt x -> x
  | Add (e1, e2) -> aux e1 env + aux e2 env
  | Mul (e1, e2) -> aux e1 env * aux e2 env
  | Sum (id, e1, e2, e3) ->
    let rec sum n i stop body id =
      if i<=stop then sum (n+(aux body ((id, i)::env))) (i+1) stop body id
      else n
    in sum 0 (aux e1 env) (aux e2 env) e3 id
in aux e []

let main = interactive_loop ()
