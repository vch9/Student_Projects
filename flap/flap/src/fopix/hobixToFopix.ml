(** This module implements a compiler from Hobix to Fopix. *)

(** As in any module that implements {!Compilers.Compiler}, the source
    language and the target language must be specified. *)

module Source = Hobix
module S = Source.AST
module Target = Fopix
module T = Target.AST

(**

   The translation from Hobix to Fopix turns anonymous
   lambda-abstractions into toplevel functions and applications into
   function calls. In other words, it translates a high-level language
   (like OCaml) into a first order language (like C).

   To do so, we follow the closure conversion technique.

   The idea is to make explicit the construction of closures, which
   represent functions as first-class objects. A closure is a block
   that contains a code pointer to a toplevel function [f] followed by all
   the values needed to execute the body of [f]. For instance, consider
   the following OCaml code:

   let f =
     let x = 6 * 7 in
     let z = x + 1 in
     fun y -> x + y * z

   The values needed to execute the function "fun y -> x + y * z" are
   its free variables "x" and "z". The same program with explicit usage
   of closure can be written like this:

   let g y env = env[1] + y * env[2]
   let f =
      let x = 6 * 7 in
      let z = x + 1 in
      [| g; x; z |]

   (in an imaginary OCaml in which arrays are untyped.)

   Once closures are explicited, there are no more anonymous functions!

   But, wait, how to we call such a function? Let us see that on an
   example:

   let f = ... (* As in the previous example *)
   let u = f 0

   The application "f 0" must be turned into an expression in which
   "f" is a closure and the call to "f" is replaced to a call to "g"
   with the proper arguments. The argument "y" of "g" is known from
   the application: it is "0". Now, where is "env"? Easy! It is the
   closure itself! We get:

   let g y env = env[1] + y * env[2]
   let f =
      let x = 6 * 7 in
      let z = x + 1 in
      [| g; x; z |]
   let u = f[0] 0 f

   (Remark: Did you notice that this form of "auto-application" is
   very similar to the way "this" is defined in object-oriented
   programming languages?)

*)

(**
   Helpers functions.
*)

let is_binop = function
  | "`+`"
  | "`-`"
  | "`*`"
  | "`/`"
  | "`>?`"
  | "`>=?`"
  | "`<?`"
  | "`<=?`"
  | "`=?`"
  | "`&&`"
  | "`||`" -> true
  | _ -> false
      
let predef = [
    ("allocate_block", 1);
    ("read_block", 2);
    ("write_block", 3);
    ("equal_string", 2);
    ("equal_char", 2);
    ("observe_int", 1);
    ("print_int", 1);
    ("print_string", 1);
  ]
  
let error pos msg =
  Error.error "compilation" pos msg

let make_fresh_variable =
  let r = ref 0 in
  fun () -> incr r; T.Id (Printf.sprintf "_%d" !r)


let make_fresh_function_identifier =
  let r = ref 0 in
  fun () -> incr r; T.FunId (Printf.sprintf "_%d" !r)

let define e f =
  let x = make_fresh_variable () in
  T.Define (x, e, f x)

let rec defines ds e =
  match ds with
    | [] ->
      e
    | (x, d) :: ds ->
      T.Define (x, d, defines ds e)

let seq a b =
  define a (fun _ -> b)

let rec seqs = function
  | [] -> assert false
  | [x] -> x
  | x :: xs -> seq x (seqs xs)

let allocate_block e =
  T.(FunCall (FunId "allocate_block", [e]))

let write_block e i v =
  T.(FunCall (FunId "write_block", [e; i; v]))

let read_block e i =
  T.(FunCall (FunId "read_block", [e; i]))

let lint i =
  T.(Literal (LInt (Int64.of_int i)))



(** [free_variables e] returns the list of free variables that
     occur in [e].*)
let free_variables =
  let module M =
    Set.Make (struct type t = S.identifier let compare = compare end)
  in
  let rec unions f = function
    | [] -> M.empty
    | [s] -> f s
    | s :: xs -> M.union (f s) (unions f xs)
  in
  let rec fvs = function
    | S.Literal l ->
      M.empty
    | S.Variable (S.Id x) ->
      if is_binop x || (List.mem x (List.map fst predef)) then M.empty
      else M.singleton (S.Id x)        
    | S.While (cond, e) ->
      unions fvs [cond; e]
    | S.Define (S.SimpleValue (i, e), a) ->
      M.diff (unions fvs (a::[e])) (M.of_list [i])
    | S.Define (S.RecFunctions xs, a) ->
      let ids, exs = List.split xs in
      M.diff (unions fvs (a::exs)) (M.of_list ids)
    | S.ReadBlock (a, b) ->
      unions fvs [a; b]
    | S.Apply (a, bs) ->
      unions fvs (a::bs)
    | S.WriteBlock (a, b, c) | S.IfThenElse (a, b, c) ->
      unions fvs [a; b; c]
    | S.AllocateBlock a ->
      fvs a
    | S.Fun (xs, e) ->
      M.diff (fvs e) (M.of_list xs)
    | S.Switch (a, b, c) ->
      let c = match c with None -> [] | Some c -> [c] in
      unions fvs (a :: ExtStd.Array.present_to_list b @ c)
  in
  fun e -> M.elements (fvs e)

(**

    A closure compilation environment relates an identifier to the way
    it is accessed in the compiled version of the function's
    body.

    Indeed, consider the following example. Imagine that the following
    function is to be compiled:

    fun x -> x + y

    In that case, the closure compilation environment will contain:

    x -> x
    y -> "the code that extract the value of y from the closure environment"

    Indeed, "x" is a local variable that can be accessed directly in
    the compiled version of this function's body whereas "y" is a free
    variable whose value must be retrieved from the closure's
    environment.

*)
type environment = {
    vars : (HobixAST.identifier, FopixAST.expression) Dict.t;
    externals : (HobixAST.identifier, int) Dict.t;
}

let initial_environment () =
  { vars = Dict.empty; externals = Dict.empty }

let bind_external id n env =
  { env with externals = Dict.insert id n env.externals }


let add_external env =
  List.fold_left (fun dict (x,n) ->
      let id = S.Id x in
      bind_external id n dict)
    env predef
  
let is_external id env =
  Dict.lookup id env.externals <> None

let reset_vars env =
   { env with vars = Dict.empty }

(** Precondition: [is_external id env = true]. *)
let arity_of_external id env =
  match Dict.lookup id env.externals with
    | Some n -> n
    | None -> assert false (* By is_external. *)


(** [translate p env] turns an Hobix program [p] into a Fopix program
    using [env] to retrieve contextual information. *)
let translate (p : S.t) env =
  let rec program env defs =
    let env, defs = ExtStd.List.foldmap definition env defs in
    (List.flatten defs, env)
  and definition env = function
    | S.DeclareExtern (id, n) ->
       let env = bind_external id n env in
       (env, [T.ExternalFunction (function_identifier id, n)])
    | S.DefineValue vd ->
       (env, value_definition env vd)
  and value_definition env = function
    | S.SimpleValue (x, e) ->
       let fs, e = expression env e in
       fs @ [T.DefineValue (identifier x, e)]
    | S.RecFunctions fdefs ->
       let fs, defs = define_recursive_functions fdefs in
       fs @ List.map (fun (x, e) -> T.DefineValue (x, e)) defs

  and define_recursive_functions fdefs =
    (* let ids = List.map fst fdefs in *)
    List.fold_left
      (fun (fs', e') x ->
         match x with
         | (id, x) ->
           let fv = free_variables (S.Define (S.RecFunctions fdefs, x)) in
           match x with
           | S.Fun (x, ex) ->
             let fs, e = closure x ex fv (reset_vars env) in
             (fs'@fs, (identifier id,e)::e')
           | _ -> assert false
      ) ([], []) fdefs
      
  and defines_writes id = function
    | [] -> id
    | [e] -> T.Define (T.Id "_", e, id)
    | e::s -> T.Define (T.Id "_", e, defines_writes id s)
                
  and writes_to_block env id fv =
    let id = T.Variable id in
    let (_, env, writes) = List.fold_left
        (fun (i, env, l) v ->
           let _, e = expression env (S.Variable v) in
           let w = write_block id (lint i) e in
           let env = { env with vars = Dict.insert v (read_block (T.Variable (T.Id "_closure")) (lint i)) env.vars } in 
           (i+1, env, w::l) 
        )
        (1, env, []) fv
    in (env, defines_writes id writes)

  and create_block fv env  =
    let size = 1 + (List.length fv) in
    let block = size |> lint |> allocate_block in
    let id = make_fresh_variable () in
    let (env, writes) = writes_to_block env id fv in
    (id, block, env, writes)
      
  and closure x e fv env =
    let (id, block, env, writes) = create_block fv env in
    
    let fs, e = expression env e in
    let funid = make_fresh_function_identifier () in
    let fun' = T.DefineFunction (funid, List.map identifier x@[(T.Id "_closure")], e) in

    let ptr = T.Define (T.Id "_", write_block (T.Variable id) (lint 0) (T.Literal (T.LFun funid)), writes) in
    let closure = T.Define (id, block, ptr) in
    fs@[fun'], closure

  and apply env a bs =
    let fs, a = expression env a in
    let bfs, bs = expressions env bs in
    match a with
    | T.Variable (T.Id x) ->
      let id = S.Id x in
      let e =
        if (is_external id env && (arity_of_external id env = List.length bs)) || is_binop x then
          T.FunCall (T.FunId x, bs)        
        else 
          T.UnknownFunCall (read_block (T.Variable (T.Id x)) (lint 0), bs@[T.Variable (T.Id x)])
      in fs@bfs, e
    | T.Literal (T.LFun id) -> assert false
    | e ->
      let fresh = make_fresh_variable () in
      let var = T.Variable (fresh) in
      let call = T.UnknownFunCall (read_block var (lint 0), bs@[var]) in
      let def = T.Define (fresh, e, call) in
      fs@bfs, def
      
  and expression env = function
    | S.Literal l ->
      [], T.Literal (literal l)
    | S.While (cond, e) ->
       let cfs, cond = expression env cond in
       let efs, e = expression env e in
       cfs @ efs, T.While (cond, e)
    | S.Variable x ->
      let xc =
        match Dict.lookup x env.vars with
          | None -> T.Variable (identifier x)
          | Some e -> e
      in
      ([], xc)
    | S.Define (vdef, a) ->
      let fs = value_definition env vdef in
      let fs', a = expression env a in
      let (defs, expr) = match fs with
      | [T.DefineValue (i, e)] -> ([], T.Define (i, e, a))
      | fdefs -> (fs, a)
      in
      defs@fs', expr
      
    | S.Apply (a, bs) ->
      apply env a bs
    | S.IfThenElse (a, b, c) ->
      let afs, a = expression env a in
      let bfs, b = expression env b in
      let cfs, c = expression env c in
      afs @ bfs @ cfs, T.IfThenElse (a, b, c)
    | S.Fun (x, e) as f ->
      closure x e (free_variables f) env
    | S.AllocateBlock a ->
      let afs, a = expression env a in
      (afs, allocate_block a)
    | S.WriteBlock (a, b, c) ->
      let afs, a = expression env a in
      let bfs, b = expression env b in
      let cfs, c = expression env c in
      afs @ bfs @ cfs,
      T.FunCall (T.FunId "write_block", [a; b; c])
    | S.ReadBlock (a, b) ->
      let afs, a = expression env a in
      let bfs, b = expression env b in
      afs @ bfs,
      T.FunCall (T.FunId "read_block", [a; b])
    | S.Switch (a, bs, default) ->
      let afs, a = expression env a in
      let bsfs, bs =
        ExtStd.List.foldmap (fun bs t ->
                    match ExtStd.Option.map (expression env) t with
                    | None -> (bs, None)
                    | Some (bs', t') -> (bs @ bs', Some t')
                  ) [] (Array.to_list bs)
      in
      let dfs, default = match default with
        | None -> [], None
        | Some e -> let bs, e = expression env e in bs, Some e
      in
      afs @ bsfs @ dfs,
      T.Switch (a, Array.of_list bs, default)


  and expressions env = function
    | [] ->
       [], []
    | e :: es ->
       let efs, es = expressions env es in
       let fs, e = expression env e in
       fs @ efs, e :: es

  and literal = function
    | S.LInt x -> T.LInt x
    | S.LString s -> T.LString s
    | S.LChar c -> T.LChar c

  and identifier (S.Id x) = T.Id x

  and function_identifier (S.Id x) = T.FunId x

  in
  let env = add_external env in
  program env p
