(** From Hopix to Hobix *)

module Source = Hopix
module Target = Hobix

(** The compilation environment.
    ———————————————————————————–

    To translate a program written in a source language into another
    semantically equivalent program written in a target language, it
    is convenient to carry some information about the correspondence
    between the two programs along the process. The compilation
    environment is meant to that.

    In this particular pass, we want to remember an assignment of
    integers to constructor and label identifiers. Therefore, the
    compilation environment is composed of two maps representing these
    assignments. The environment is populated each time we cross a
    type definitions while it is read each time we translate language
    constructions related to record and tagged values.
*)

module ConstructorMap = Map.Make (struct
  type t = HopixAST.constructor
  let compare = compare
end)

module LabelMap = Map.Make (struct
  type t = HopixAST.label
  let compare = compare
end)

type environment = {
  constructor_tags : Int64.t ConstructorMap.t;
  label_positions  : Int64.t LabelMap.t;
}

let initial_environment () = {
  constructor_tags = ConstructorMap.empty;
  label_positions  = LabelMap.empty;
}

let index_of_constructor env k =
  ConstructorMap.find k env.constructor_tags

let position_of_label env l =
  LabelMap.find l env.label_positions

let add_index_of_constructor env k i =
  {env with constructor_tags = ConstructorMap.add k i env.constructor_tags}
    
let add_position_of_label env l i =
  {env with label_positions = LabelMap.add l i env.label_positions }

(** Code generation
    ———————————————

    A compilation pass produces code. We could directly
    write down caml expressions made of applications of
    HobixAST constructors. Yet, the resulting code would
    be ugly...

    A better way consists in defining functions that build
    Hobix AST terms and are convenient to use. Here are a
    list of functions that may be convenient to you when
    you will implement this pass.

*)

(** [fresh_identifier ()] returns a fresh identifier, that is
    an identifier that has never been seen before. *)
let fresh_identifier =
  let r = ref 0 in
  fun () -> incr r; HobixAST.Id ("_" ^ string_of_int !r)

(** [def w (fun x -> e)] returns an abstract syntax tree of
    the form:

    val x = w; e

    where [x] is chosen fresh.
*)
let def w f =
  let x = fresh_identifier () in
  HobixAST.(Define (SimpleValue (x, w), f x))

(** [defines [d1; ..; dN] e] returns an abstract syntax tree of
    the form:

    val d1;
    ..
    val dN;
    e

*)
let defines =
  List.fold_right (fun (x, xe) e ->
      HobixAST.(Define (SimpleValue (x, xe), e)))

(** [seq s1 s2] is

    val _ = s1;
    s2

*)
let seq s1 s2 =
  HobixAST.(Define (SimpleValue (fresh_identifier (), s1), s2))

(** [htrue] represents the primitive true in Hobix. *)
let htrue =
  HobixAST.(Variable (Id "true"))

(** [seqs [s1; ...; sN] is

    val _ = s1;
    ...
    val _ = s(N - 1);
    sN
*)
let rec seqs = function
  | [] -> assert false
  | [e] -> e
  | e :: es -> seq e (seqs es)

(** [is_equal e1 e2] is the boolean expression [e1 = e2]. *)
let is_equal l e1 e2 =
  let equality = HobixAST.(match l with
    | LInt _ -> "`=?`"
    | LString _ -> "equal_string"
    | LChar _ -> "equal_char"
  ) in
  HobixAST.(Apply (Variable (Id equality), [e1; e2]))

(** [conj e1 e2] is the boolean expression [e1 && e2]. *)
let conj e1 e2 =
  HobixAST.(Apply (Variable (Id "`&&`"), [ e1; e2 ]))

(** [conjs [e1; ..; eN]] is the boolean expression [e1 && .. && eN]. *)
let rec conjs = HobixAST.(function
  | [] -> htrue
  | [c] -> c
  | c :: cs -> conj c (conjs cs)
)

(** [component x i] returns [x[i]] where x is an Hobix expression
    denoting a block. *)
let component x i =
  failwith "Students! This is your job!"


let located  f x = f (Position.value x)
let located' f x = Position.map f x
let explode x = Position.value x
let explodes l = List.map (Position.value) l

let arity_of_type = HopixAST.(function
  | TyVar _           -> 0
  | TyCon (_, _)     -> 0
  | TyArrow (_, _) -> 1
  | TyTuple _ -> 0
  )

(* Helpers *)
let is_bin_op b =
  let bin = 
  [
    "`+`";
    "`*`";
    "`-`";
    "`/`";
    
    "`=?`";
    "`<?`";
    "`>?`";
    "`<=?`";
    "`>=?`";

    "`||`";
    "`&&`"; 
  ]
  in
  List.map (fun (x) -> (HobixAST.Id x)) bin |>
  List.mem b
 

(** 
   We receive  element (e),
   list of patterns (ps).
   We return associations of every pattern
   in ps with e
*)
let add_every_pattern e ps =
  List.fold_left
    (fun acc p ->
       (e @ [p]) :: acc
    ) [] ps

(**
   We receive a list of pattern (ps),
   and for each pattern create all the posibilites
   of associations, with the current accumulator
*)
let rec iterate_on_patterns acc = function
  | p::ps ->
    let acc = List.fold_left
        (fun acc x ->
           (add_every_pattern x p) @ acc
        ) [] acc
    in
    iterate_on_patterns acc ps
  | [] -> acc
    
let compare_labels (HopixAST.LId x) (HopixAST.LId y) =
  compare x y

let sort_labels labels =
  List.sort (fun x y -> compare_labels x y) labels

let sort_labels_exprs les =
  List.sort (fun (x, _) (y, _) -> compare_labels x y) les

let int_to_int64 n =
  Int64.of_int n
  
let int_to_lint n =
  HobixAST.LInt n

let expr_of_lit l =
  HobixAST.Literal l

let expr_of_int i =
  i |> int_to_int64 |> int_to_lint |> expr_of_lit

let expr_of_int64 i =
  i |> int_to_lint |> expr_of_lit
  
let create_block n =
  let l = expr_of_int n in
  HobixAST.AllocateBlock l

let assign_block b i v =
  let i = expr_of_int i in
  HobixAST.WriteBlock (b, i, v)

(** [program env p] turns an Hopix program into an equivalent
    Hobix program. *)
let rec program env p =
  let env, defs = ExtStd.List.foldmap definition' env p in
  (List.flatten defs, env)

(** Compilation of Hopix toplevel definitions. *)
and definition' env p =
  definition env (Position.value p)

and definition env = HobixAST.(function
  | HopixAST.DeclareExtern (x, s) ->
    let { Position.value = HopixAST.ForallTy (_, ty); _ } = s in
    let ty = Position.value ty in
    env, [DeclareExtern (located identifier x, arity_of_type ty)]

  | HopixAST.DefineValue vd ->
     let vd = value_definition env vd in
     env, [DefineValue vd]

  | HopixAST.DefineType (_, _, tydef) ->
    type_definition env tydef, []
)

and value_definition env = function
  | HopixAST.SimpleValue (x, _, e) ->
     HobixAST.SimpleValue (located identifier x, located (expression env) e)
  | HopixAST.RecFunctions fs ->
     HobixAST.RecFunctions (List.map (function_binding env) fs)

and function_binding env (f, _, fdef) =
  (located identifier f, function_definition env fdef)

and function_definition env (HopixAST.FunctionDefinition (x, e)) =
  let y = HopixASTHelper.fresh_identifier () in
  let wpos t = Position.(with_pos (position x) t) in
  let e = HopixAST.(
      Case (wpos (Variable (wpos y, None)),
            [
              wpos (Branch (x, e))
            ])
  )
  in
  (HobixAST.Fun ([identifier y], expression env e))

and identifier (HopixAST.Id x) =
  HobixAST.Id x

(** Compilation of Hopix expressions. *)
and expression env = HobixAST.(function
  | HopixAST.Variable (x, _) ->
    variable env x
      
  | HopixAST.Tagged (k, _, es) ->
    tagged env k es

  | HopixAST.Case (e, bs) ->
    case env e bs

  | HopixAST.Ref e ->
    ref' env e

  | HopixAST.Read r ->
    read env r

  | HopixAST.Assign (r, v) ->
    assign env r v

  | HopixAST.While (c, b) ->
    HobixAST.While (located (expression env) c,
                    located (expression env) b)

  | HopixAST.Apply (a, b) ->
    Apply (located (expression env) a,
           [located (expression env) b])

  | HopixAST.Literal l ->
    Literal (located literal l)

  | HopixAST.Define (vd, e) ->
    Define (value_definition env vd, located (expression env) e)

  | HopixAST.TypeAnnotation (e, ty) ->
    located (expression env) e

  | HopixAST.IfThenElse (c, t, f) ->
     let f = located (expression env) f in
     HobixAST.IfThenElse (located (expression env) c,
                          located (expression env) t,
                          f)

  | HopixAST.Record (fs, _) ->
    record env fs

  | HopixAST.Tuple ts ->
    tuple env ts

  | HopixAST.Field (e, l) ->
    field env e l

  | HopixAST.Sequence es ->
    seqs (List.map (located (expression env)) es)

  | HopixAST.For (x, start, stop, e) ->
    for' env x start stop e 

  | HopixAST.Fun (fdef) ->
    function_definition env fdef
)

and variable env x = HobixAST.(
  let x = located identifier x in
  if is_bin_op x then
    let op = Variable x in
    let e0 = fresh_identifier () in
    let e1 = fresh_identifier () in
    let body_args = List.map (fun x -> Variable x) [e0; e1] in

    let f2 = Fun (
        [e1],
        Apply (
          op,
          body_args
        )
      )
    in
    let f = Fun (
        [e0],
        f2
      )
    in f
                           
  else
    Variable x
)

and ref' env e =
  let e = located (expression env) e in
  let block = create_block 1 in
  let fresh = fresh_identifier () in
  let id = HobixAST.Variable fresh in
  let write = assign_block id 0 e in
  HobixAST.Define (
    HobixAST.SimpleValue (fresh, block),
    seq write (id)      
  )

and read env b =
  let b = located (expression env) b in
  HobixAST.ReadBlock (b, expr_of_int 0)

and assign env r v =
  let b = located (expression env) r in
  let v = located (expression env) v in
  assign_block b 0 v

and record env fs =
  (* Sort labels * expressions *)
  let fs = List.map (fun (x,y) -> explode x, y) fs in
  let fs = sort_labels_exprs fs in

  (* Fresh id for the block *)
  let fresh = fresh_identifier () in
  let id = HobixAST.Variable fresh in
  
  let b = create_block (List.length fs) in
  
  let writes = List.fold_left
      (fun acc (l,e) ->
         let i = position_of_label env l in
         let v = located (expression env) e in
         assign_block id (Int64.to_int i) v :: acc) [] fs
  in
  HobixAST.Define (
    HobixAST.SimpleValue (fresh, b),
    seqs (writes@[id])
  )

and tuple env ts =
  (* Fresh id for the block *)
  let fresh = fresh_identifier () in
  let id = HobixAST.Variable fresh in
  
  let b = create_block (List.length ts) in

  let (writes, _) = List.fold_left
      (fun (acc, i) e ->
         let v = located (expression env) e in
         (assign_block id i v :: acc, i+1)
      ) ([], 0) ts

  in
  HobixAST.Define (
    HobixAST.SimpleValue (fresh, b),
    seqs (writes@[id])
  )

and field env e l =
  let b = located (expression env) e in
  let i = position_of_label env (explode l) in
  HobixAST.ReadBlock (b, expr_of_int64 i)

and tagged env k es =
  let index = index_of_constructor env (explode k) in
  
  (* Fresh id for the block *)
  let fresh = fresh_identifier () in
  let id = HobixAST.Variable fresh in

  let b = create_block ((List.length es)+1) in

  let (writes, _) = List.fold_left
      (fun (acc, i) e ->
         let v = located (expression env) e in
         (assign_block id i v :: acc, i+1)
      ) ([], 1) es
  in
  let writes = assign_block id 0 (expr_of_int64 index) :: writes in
  HobixAST.Define(
    HobixAST.SimpleValue (fresh, b),
    seqs (writes@[id])
  )

and case env e bs =
  let not_going_to_work =
    HobixAST.Apply (
      HobixAST.Variable (Id "`/`"),
      [ HobixAST.Literal (LInt (1L));
        HobixAST.Literal (LInt (0L));
      ]
    )
  in
  let defs scrutinee p e =    
      let (c, dfs) = located (pattern env scrutinee) p in
      let e = located (expression env) e in
      (c, defines dfs e)
  in
  let rec branch_into_ifelse scrutinee = function
    | HopixAST.Branch (p, e) :: xs ->
      let (c, defs) = defs scrutinee p e in
      HobixAST.IfThenElse (seqs c, defs, branch_into_ifelse scrutinee xs)
    | [] ->
      not_going_to_work
  in      
  let bs = expands_or_patterns bs in
  let scrutinee = located (expression env) e in
  branch_into_ifelse scrutinee (explodes bs)

and for' env x start stop e =
  (* Translate hopix.identifier to hobix.identifier and create a variable hobix.variable *)
  let hobix_x = located (identifier) x in
  let var_x = HobixAST.Variable (hobix_x) in

  (* Create block for hobix.x *)
  let block_init = HobixAST.SimpleValue (hobix_x, create_block 1) in
  let init = HobixAST.WriteBlock (var_x, expr_of_int 0, located (expression env) start) in

  (* Create comparison *)
  let c = HobixAST.Apply
      (HobixAST.Variable (Id "`<?`"),
       [ HobixAST.ReadBlock (var_x, expr_of_int 0);
         located (expression env) stop
       ]
      )
  in
  let c_and_body = HobixAST.While (c, located (expression env) e) in
  HobixAST.Define (
    block_init,
    HobixAST.Define (
      HobixAST.SimpleValue (Id "_", init),
      c_and_body
    )
  )
    
(** [expands_or_patterns branches] returns a sequence of branches
    equivalent to [branches] except that their patterns do not contain
    any disjunction. {ListMonad} can be useful to implement this
    transformation. *)
and expands_or_patterns branchs =
  let open HopixAST in

  let rec explode_pattern p =
    let explodes_patterns ps =      
      let ps = List.map (fun x -> explode_pattern x) ps in
      iterate_on_patterns [[]] ps
    in
    match Position.value p with
    | PVariable _ | PWildcard | PLiteral _ ->
      [p]
      
    | PTuple ps ->
      let l_ps = explodes_patterns ps in
      List.map (fun ps -> Position.with_pos p.position (PTuple ps)) l_ps

    | POr ps ->
      List.fold_left
        (fun acc p ->
           p :: acc
        ) [] ps

    | PAnd ps ->
      let l_ps = explodes_patterns ps in
      List.map (fun ps -> Position.with_pos p.position (PAnd ps)) l_ps
      
        
    | PTypeAnnotation (p, ty) ->
      let ps = explode_pattern p in
      List.map (fun x -> Position.with_pos p.position (PTypeAnnotation (x, ty)) ) ps
        
    | PTaggedValue (c, tys, ps) ->      
      let l_ps = explodes_patterns ps in
      List.map (fun ps -> Position.with_pos p.position (PTaggedValue (c, tys, ps))) l_ps
        
    | PRecord (lp_l, ty) ->
      let ls, ps = List.split lp_l in      
      let l_ps = explodes_patterns ps in
      List.map (fun ps -> Position.with_pos p.position (PRecord (List.combine ls ps, ty))) l_ps
  in
  List.fold_left
    (fun acc branch -> match Position.value branch with
       | Branch (p, e) ->
         let patterns = explode_pattern p in
         List.fold_left
           (fun branches p ->
              Position.with_pos branch.position (Branch (p, e)) :: branches
           ) [] patterns
         @ acc
    ) [] branchs
    
(** [pattern env scrutinee p] returns an HopixAST expression
    representing a boolean condition [c] and a list of definitions
    [ds] such that:

    - [c = true] if and only if [p] matches the [scrutinee] ;
    - [ds] binds all the variables that appear in [p].

    Precondition: p does not contain any POr.
 *)
and pattern env scrutinee p = HobixAST.(match p with
    | HopixAST.PVariable id ->
      [htrue], [(located identifier id, scrutinee)]
    | HopixAST.PWildcard ->
      [htrue], []
    | HopixAST.PTypeAnnotation (p, _) ->
      pattern env scrutinee p.value
    | HopixAST.PLiteral lit ->
      let lit = located literal lit in
      [is_equal lit scrutinee (Literal lit)], []
    | HopixAST.PTaggedValue (k, _, ps) ->
      let k = index_of_constructor env k.value in
      let c = is_equal (LInt 0L) (ReadBlock (scrutinee, Literal (LInt 0L))) (Literal (LInt k)) in

      let i = ref 1L in
      
      List.fold_left
        (fun (cs, dfs) x ->
           let cs', dfs' = pattern env (ReadBlock (scrutinee, Literal (LInt !i))) x in
           i := Int64.add !i 1L;
           cs@cs', dfs@dfs'
        ) ([c], []) (List.map Position.value ps)

    | HopixAST.PRecord (lps, _) ->
      List.fold_left
        (fun (cs, dfs) (l, p) ->
           let k = position_of_label env (explode l) in
           let cs', dfs' = pattern env (ReadBlock (scrutinee, Literal (LInt k))) (explode p) in
           cs@cs', dfs@dfs'
        ) ([], []) lps

    | HopixAST.PTuple ps ->
      let (cs, dfs, _) = 
        List.fold_left
          (fun (cs, dfs, i) p ->
             let cs', dfs' = pattern env (ReadBlock (scrutinee, Literal (LInt i))) (explode p) in
             cs@cs', dfs@dfs', Int64.add i 1L
          ) ([], [], 0L) ps
      in cs, dfs

    | HopixAST.PAnd ps ->
      List.fold_left
        (fun (cs, dfs) p ->
           let cs', dfs' = pattern env scrutinee (explode p) in
           cs@cs', dfs@dfs'
        ) ([], []) ps
      
    | HopixAST.POr _ ->
      assert false (* by typing *)
)

and literal = HobixAST.(function
  | HopixAST.LInt x -> LInt x
  | HopixAST.LString s -> LString s
  | HopixAST.LChar c -> LChar c
)

(** Compilation of type definitions. *)
and type_definition env =
  let (+) =
    Int64.add
  in
  let td env = function
  | HopixAST.Abstract ->
    env
  | HopixAST.DefineRecordType labels ->
    let (labels, _) = List.split labels in
    let labels = explodes labels |> sort_labels in
    let (env, _) = List.fold_left
        (fun (env, i) l ->
           (add_position_of_label env l i, i+1L)
        ) (env, 0L) labels
    in
    env
  | HopixAST.DefineSumType kt ->
    let (ks, _) = List.split kt in
    
    let (env, _) = List.fold_left
        (fun (env, i) k ->
           (add_index_of_constructor env (explode k) i, i+1L)
        ) (env, 0L) ks
    in
    env
  in
  (fun e -> td env e)
  

(** Here is the compiler! *)
let translate source env =
  program env source
