open Position
open Error
open HopixAST

(** [error pos msg] reports execution error messages. *)
let error positions msg =
  errorN "execution" positions msg

(** Every expression of Hopix evaluates into a [value].

   The [value] type is not defined here. Instead, it will be defined
   by instantiation of following ['e gvalue] with ['e = environment].
   Why? The value type and the environment type are mutually recursive
   and since we do not want to define them simultaneously, this
   parameterization is a way to describe how the value type will use
   the environment type without an actual definition of this type.

*)
type 'e gvalue =
  | VInt       of Mint.t
  | VChar      of char
  | VString    of string
  | VUnit
  | VTagged    of constructor * 'e gvalue list
  | VTuple     of 'e gvalue list
  | VRecord    of (label * 'e gvalue) list
  | VLocation  of Memory.location
  | VClosure   of 'e * pattern located * expression located
  | VPrimitive of string * ('e gvalue Memory.t -> 'e gvalue -> 'e gvalue)

(** Two values for booleans. *)
let ptrue  = VTagged (KId "True", [])
let pfalse = VTagged (KId "False", [])

(**
    We often need to check that a value has a specific shape.
    To that end, we introduce the following coercions. A
    coercion of type [('a, 'e)] coercion tries to convert an
    Hopix value into a OCaml value of type ['a]. If this conversion
    fails, it returns [None].
*)

type ('a, 'e) coercion = 'e gvalue -> 'a option
let fail = None
let ret x = Some x
let value_as_int      = function VInt x -> ret x | _ -> fail
let value_as_char     = function VChar c -> ret c | _ -> fail
let value_as_string   = function VString s -> ret s | _ -> fail
let value_as_tagged   = function VTagged (k, vs) -> ret (k, vs) | _ -> fail
let value_as_record   = function VRecord fs -> ret fs | _ -> fail
let value_as_location = function VLocation l -> ret l | _ -> fail
let value_as_closure  = function VClosure (e, p, b) -> ret (e, p, b) | _ -> fail
let value_as_primitive = function VPrimitive (p, f) -> ret (p, f) | _ -> fail
let value_as_bool = function
  | VTagged (KId "True", []) -> true
  | VTagged (KId "False", []) -> false
  | _ -> assert false

(**
   It is also very common to have to inject an OCaml value into
   the types of Hopix values. That is the purpose of a wrapper.
 *)
type ('a, 'e) wrapper = 'a -> 'e gvalue
let int_as_value x  = VInt x
let bool_as_value b = if b then ptrue else pfalse

(**

  The flap toplevel needs to print the result of evaluations. This is
   especially useful for debugging and testing purpose. Do not modify
   the code of this function since it is used by the testsuite.

*)
let print_value m v =
  (** To avoid to print large (or infinite) values, we stop at depth 5. *)
  let max_depth = 5 in

  let rec print_value d v =
    if d >= max_depth then "..." else
      match v with
        | VInt x ->
          Mint.to_string x
        | VChar c ->
          "'" ^ Char.escaped c ^ "'"
        | VString s ->
          "\"" ^ String.escaped s ^ "\""
        | VUnit ->
          "()"
        | VLocation a ->
          print_array_value d (Memory.dereference m a)
        | VTagged (KId k, []) ->
          k
        | VTagged (KId k, vs) ->
          k ^ print_tuple d vs
        | VTuple (vs) ->
           print_tuple d vs
        | VRecord fs ->
           "{"
           ^ String.concat ", " (
                 List.map (fun (LId f, v) -> f ^ " = " ^ print_value (d + 1) v
           ) fs) ^ "}"
        | VClosure _ ->
          "<fun>"
        | VPrimitive (s, _) ->
          Printf.sprintf "<primitive: %s>" s
    and print_tuple d vs =
      "(" ^ String.concat ", " (List.map (print_value (d + 1)) vs) ^ ")"
    and print_array_value d block =
      let r = Memory.read block in
      let n = Mint.to_int (Memory.size block) in
      "[ " ^ String.concat ", " (
                 List.(map (fun i -> print_value (d + 1) (r (Mint.of_int i)))
                         (ExtStd.List.range 0 (n - 1))
               )) ^ " ]"
  in
  print_value 0 v

let print_values m vs =
  String.concat "; " (List.map (print_value m) vs)

module Environment : sig
  (** Evaluation environments map identifiers to values. *)
  type t

  (** The empty environment. *)
  val empty : t

  (** [bind env x v] extends [env] with a binding from [x] to [v]. *)
  val bind    : t -> identifier -> t gvalue -> t

  (** [update pos x env v] modifies the binding of [x] in [env] so
      that [x ↦ v] ∈ [env]. *)
  val update  : Position.t -> identifier -> t -> t gvalue -> unit

  (** [lookup pos x env] returns [v] such that [x ↦ v] ∈ env. *)
  val lookup  : Position.t -> identifier -> t -> t gvalue

  (** [UnboundIdentifier (x, pos)] is raised when [update] or
      [lookup] assume that there is a binding for [x] in [env],
      where there is no such binding. *)
  exception UnboundIdentifier of identifier * Position.t

  (** [last env] returns the latest binding in [env] if it exists. *)
  val last    : t -> (identifier * t gvalue * t) option

  (** [print env] returns a human readable representation of [env]. *)
  val print   : t gvalue Memory.t -> t -> string
end = struct

  type t =
    | EEmpty
    | EBind of identifier * t gvalue ref * t

  let empty = EEmpty

  let bind e x v =
    EBind (x, ref v, e)

  exception UnboundIdentifier of identifier * Position.t

  let lookup' pos x =
    let rec aux = function
      | EEmpty -> raise (UnboundIdentifier (x, pos))
      | EBind (y, v, e) ->
        if x = y then v else aux e
    in
    aux

  let lookup pos x e = !(lookup' pos x e)

  let update pos x e v =
    lookup' pos x e := v

  let last = function
    | EBind (x, v, e) -> Some (x, !v, e)
    | EEmpty -> None

  let print_binding m (Id x, v) =
    x ^ " = " ^ print_value m !v

  let print m e =
    let b = Buffer.create 13 in
    let push x v = Buffer.add_string b (print_binding m (x, v)) in
    let rec aux = function
      | EEmpty -> Buffer.contents b
      | EBind (x, v, EEmpty) -> push x v; aux EEmpty
      | EBind (x, v, e) -> push x v; Buffer.add_string b "\n"; aux e
    in
    aux e

end

(**
    We have everything we need now to define [value] as an instantiation
    of ['e gvalue] with ['e = Environment.t], as promised.
*)
type value = Environment.t gvalue

(**
   The following higher-order function lifts a function [f] of type
   ['a -> 'b] as a [name]d Hopix primitive function, that is, an
   OCaml function of type [value -> value].
*)
let primitive name ?(error = fun () -> assert false) coercion wrapper f
: value
= VPrimitive (name, fun x ->
    match coercion x with
      | None -> error ()
      | Some x -> wrapper (f x)
  )

type runtime = {
  memory      : value Memory.t;
  environment : Environment.t;
}

type observable = {
  new_memory      : value Memory.t;
  new_environment : Environment.t;
}

(** [primitives] is an environment that contains the implementation
    of all primitives (+, <, ...). *)
let primitives =
  let intbin name out op =
    VPrimitive (name, fun m -> function
      | VTuple [VInt x; VInt y] -> out (op x y)
      | vs ->
         Printf.eprintf
           "Invalid arguments for `%s': %s\n"
           name (print_value m vs);
         assert false (* By typing. *)
    )
  in
  let bind_all what l x =
    List.fold_left (fun env (x, v) -> Environment.bind env (Id x) (what x v))
      x l
  in
  (* Define arithmetic binary operators. *)
  let binarith name =
    intbin name (fun x -> VInt x) in
  let binarithops = Mint.(
    [ ("`+`", add); ("`-`", sub); ("`*`", mul); ("`/`", div) ]
  ) in
  (* Define arithmetic comparison operators. *)
  let cmparith name = intbin name bool_as_value in
  let cmparithops =
    [ ("`=?`", ( = ));
      ("`<?`", ( < ));
      ("`>?`", ( > ));
      ("`>=?`", ( >= ));
      ("`<=?`", ( <= )) ]
  in
  let boolbin name out op =
    VPrimitive (name, fun m -> function
      | VTuple [x; y] -> out (op (value_as_bool x) (value_as_bool y))
      | _ -> assert false (* By typing. *)
    )
  in
  let boolarith name = boolbin name (fun x -> if x then ptrue else pfalse) in
  let boolarithops =
    [ ("`||`", ( || )); ("`&&`", ( && )) ]
  in
  let generic_printer =
    VPrimitive ("print", fun m v ->
      output_string stdout (print_value m v);
      flush stdout;
      VUnit
    )
  in
  let print s =
    output_string stdout s;
    flush stdout;
    VUnit
  in
  let print_int =
    VPrimitive  ("print_int", fun m -> function
      | VInt x -> print (Mint.to_string x)
      | _ -> assert false (* By typing. *)
    )
  in
  let print_string =
    VPrimitive  ("print_string", fun m -> function
      | VString x -> print x
      | _ -> assert false (* By typing. *)
    )
  in
  let bind' x w env = Environment.bind env (Id x) w in
  Environment.empty
  |> bind_all binarith binarithops
  |> bind_all cmparith cmparithops
  |> bind_all boolarith boolarithops
  |> bind' "print"        generic_printer
  |> bind' "print_int"    print_int
  |> bind' "print_string" print_string
  |> bind' "true"         ptrue
  |> bind' "false"        pfalse
  |> bind' "nothing"      VUnit

let initial_runtime () = {
  memory      = Memory.create (640 * 1024 (* should be enough. -- B.Gates *));
  environment = primitives;
}

exception NotCapturedPattern
exception NotBinopApply

let rec evaluate runtime ast =
  try
    let runtime' = List.fold_left definition runtime ast in
    (runtime', extract_observable runtime runtime')
  with Environment.UnboundIdentifier (Id x, pos) ->
    Error.error "interpretation" pos (Printf.sprintf "`%s' is unbound." x)

(** [definition pos runtime d] evaluates the new definition [d]
    into a new runtime [runtime']. In the specification, this
    is the judgment:

                        E, M ⊢ dv ⇒ E', M'

*)
and definition runtime d = match Position.value d with
  | DeclareExtern _ -> runtime
  | DefineType (ty_c, ty_v_l, ty_def) -> runtime
  | DefineValue vd -> value_definition runtime vd

and value_definition runtime = function
  | SimpleValue (id, _, e) ->
    let va = expression' runtime.environment runtime.memory e
    in let env = Environment.bind runtime.environment (Position.value id) va
    in  { environment = env ; memory=runtime.memory }
  | RecFunctions funs -> rec_functions runtime funs

and rec_functions runtime = function
  | (id, _, FunctionDefinition(p, e))::t ->
    begin
      let v = VClosure (runtime.environment, p, e) in
      try Environment.update id.position (Position.value id) runtime.environment v; rec_functions runtime t
      with Environment.UnboundIdentifier _ -> rec_functions { environment = Environment.bind runtime.environment (Position.value id) v; memory=runtime.memory } t
    end
  | [] -> runtime

and expression' environment memory e =
  expression (position e) environment memory (value e)

(** [expression pos runtime e] evaluates into a value [v] if

                          E, M ⊢ e ⇓ v, M'

   and E = [runtime.environment], M = [runtime.memory].
*)
and expression position environment memory = function
  | Literal l -> literal (Position.value l)
  | Variable (id, _) -> Environment.lookup position (Position.value id) environment
  | Tagged (cs, ty, e_l) ->
    begin
      match Position.value cs, ty, e_l with
      | (KId "True", None, []) -> ptrue
      | (KId "False", None, [])-> pfalse
      | (c, _, e_l) ->
        let e_l = List.map (fun x -> expression' environment memory x) e_l
        in VTagged(c, e_l);
      end
  | Record (l, _) ->
    let l = List.map (fun (x,y) -> (Position.value x, expression' environment memory y)) l
    in VRecord(l)
  | Field (e, lab) ->
    begin
      let v = expression' environment memory e
      in
      match v with
      | VRecord lis ->
        begin
          try
            List.assoc (Position.value lab) lis
          with Not_found -> failwith "record has no such field"
        end
      | _ -> failwith "ill_typed field"
    end
  | Tuple (l) ->
    let l = List.map (fun x -> expression' environment memory x) l
    in VTuple (l)
  | Sequence (l) ->
    begin
      match l with
      | e1::e2::[] ->
        let _ = expression' environment memory e1
        in expression' environment memory e2
      | _ -> failwith "invalid built sequence"
    end
  | Define (vd, e) ->
    let runtime = value_definition { memory=memory ; environment=environment} vd
    in expression' runtime.environment runtime.memory e
  | Fun (FunctionDefinition (p, e)) -> VClosure (environment, p, e)
  | Apply (e1, e2) -> apply e1 e2 environment memory
  | Ref (e) ->
    let v = expression' environment memory e in
    let block = Memory.allocate memory 1L v in
    VLocation block
  | Assign (e1, e2) ->
    let e1 = expression' environment memory e1 in
    let e2 = expression' environment memory e2 in
    begin
      match e1 with
      | VLocation a -> Memory.write (Memory.dereference memory a) 0L e2; VUnit
      | _ -> failwith "e1 := e2, no adress found for e1"
    end
  | Read (e) ->
    let e = expression' environment memory e in
    begin
      match e with
      | VLocation a -> Memory.read (Memory.dereference memory a) 0L
      | _ -> failwith "!e, no adress found for e"
    end
  | Case (e, b_l) ->
    let v = expression' environment memory e in
    branchs environment memory v (List.map (fun x -> Position.value x) b_l)
  | IfThenElse (e1, e2, e3) ->
    let runtime = { memory=memory ; environment=environment } in
    let e1 = expression' runtime.environment runtime.memory e1
    in if value_as_bool e1 then expression' runtime.environment runtime.memory e2
    else expression' runtime.environment runtime.memory e3
  | While (e1, e2) ->
    begin
      let v1 = expression' environment memory e1 in
      match v1 with
      | VTagged (KId "True", []) | VTagged (KId "False", []) -> while_loop environment memory e1 e2
      | _ -> failwith "ill_typed while"
    end
  | For (i, e1, e2, e3) ->
    begin
      let v1 = expression' environment memory e1 in
      let v2 = expression' environment memory e2 in
      match Position.value i, v1, v2 with
      | (Id s, VInt x, VInt y) -> for_loop position (Environment.bind environment (Position.value i) v1) memory i y e3
      | _ ->  failwith "ill_typed for"
    end
  | TypeAnnotation (e, ty) -> expression' environment memory e

and while_loop environment memory e1 e2 =
  let v1 = expression' environment memory e1 in
  match value_as_bool v1 with
  | true ->
    let _ = expression' environment memory e2
    in while_loop environment memory e1 e2
  | false -> VUnit

and for_loop position environment memory id y e3 =
  let v = (Environment.lookup position (Position.value id) environment) in
  match v with
  | VInt a ->
    begin
      match a<=y with
      | true ->
        let _ = expression' environment memory e3 in
        let new_value = (Environment.lookup position (Position.value id) environment) in
        begin
          match new_value with
          | VInt a ->
            let new_id_v = VInt (Int64.add a 1L) in
            Environment.update id.position (Position.value id) environment new_id_v;
            for_loop position environment memory id y e3
          | _ -> failwith "ill_typed identifier for loop"
        end
      | _ -> VUnit
    end
  | _ -> failwith "ill_typed identifier for loop"

and literal = function
  | LInt x -> VInt x
  | LChar x -> VChar x
  | LString x -> VString x

and pattern v environment memory = function
  | PWildcard -> { environment=environment ; memory=memory }
  | PVariable id -> { environment = Environment.bind environment (Position.value id) v ; memory=memory }
  | PTypeAnnotation (p, ty) -> pattern v environment memory (Position.value p)
  | PLiteral lit ->
    let lit = literal (Position.value lit) in
    begin match lit, v with
    | (VInt x, VInt y) -> if x=y then { environment=environment ; memory=memory } else raise NotCapturedPattern
    | (VChar x, VChar y) -> if x=y then { environment=environment ; memory=memory } else raise NotCapturedPattern
    | (VString x, VString y) -> if x=y then { environment=environment ; memory=memory } else raise NotCapturedPattern
    | _ -> raise NotCapturedPattern
    end
  | PTaggedValue ({value=KId c; position=pos}, _, p_l) ->
    begin
      match v with
      | VTagged (KId c', v_l) ->
        if c<>c' || (List.length p_l)!=(List.length v_l) then
          begin
            raise NotCapturedPattern
          end
        else
          begin
            let rec cmp_tagged p_l v_l runtime = match (p_l, v_l) with
            | (hp::qp, hv::qv) -> cmp_tagged qp qv (pattern hv runtime.environment runtime.memory (Position.value hp))
            | ([], []) -> runtime
            | _ -> raise NotCapturedPattern
            in
            cmp_tagged p_l v_l { environment=environment ; memory=memory }
          end
      | _ -> raise NotCapturedPattern
    end
  | PRecord (lp_l, _) ->
    begin
      match v with
      | VRecord lv_l ->
        if (List.length lp_l)!=(List.length lv_l) then raise NotCapturedPattern
        else
          begin
              let rec cmp_record lp_l lv_l runtime = match (lp_l, lv_l) with
              | ( (l, hp)::lp_q, (l', hv)::lv_q ) ->
                if (Position.value l)=l' then cmp_record lp_q lv_q (pattern hv runtime.environment runtime.memory (Position.value hp))
                else raise NotCapturedPattern
              | [], [] -> runtime
              | _ -> raise NotCapturedPattern
              in
              cmp_record lp_l lv_l { environment=environment ; memory=memory }
          end
      | _ -> raise NotCapturedPattern
    end
  | PTuple l_pattern ->
    begin
      try
        begin
          match v with
          | VTuple l_value ->
            begin
              let rec cmp_ptuple runtime l_pat l_val = match l_pat, l_val with
              | hp::tp, hv::tv -> cmp_ptuple (pattern hv runtime.environment runtime.memory (Position.value hp)) tp tv
              | [], [] -> runtime
              | _ -> raise NotCapturedPattern
              in cmp_ptuple {environment=environment ; memory=memory } l_pattern l_value
            end
          | _ -> raise NotCapturedPattern
        end
      with NotCapturedPattern -> raise NotCapturedPattern
    end
  | POr p_l ->
    begin
      let rec cmp_por runtime = function
      | h::t ->
        begin
          try pattern v runtime.environment runtime.memory (Position.value h)
          with NotCapturedPattern -> cmp_por runtime t
        end
      | [] -> raise NotCapturedPattern
      in cmp_por { environment=environment ; memory=memory } p_l
    end
  (* (pi & pi+1 & .. pn) si n=0, vrai*)
  | PAnd p_l ->
    begin
      let rec cmp_pand runtime = function
      | h::t ->
        begin
          try cmp_pand (pattern v runtime.environment runtime.memory (Position.value h)) t
          with NotCapturedPattern -> raise NotCapturedPattern
        end
      | [] -> runtime
      in cmp_pand { environment=environment ; memory=memory } p_l
    end

and branchs environment memory e = function
   | [] -> failwith "no pattern found in branchs"
   | Branch (p, p_e)::t ->
      try
        let run = pattern e environment memory (Position.value p) in
        expression' run.environment run.memory p_e
      with NotCapturedPattern -> branchs environment memory e t
and apply e1 e2 environment memory =
  let v2 = expression' environment memory e2 in
  begin
    try apply_binop e1 v2 environment memory
    with NotBinopApply -> match expression' environment memory e1 with
    | VClosure (env, p, e) ->
      begin
        try
          let run = pattern v2 environment memory (Position.value p) in
          expression' run.environment run.memory e
        with NotCapturedPattern -> failwith "ill_typed apply vclosure"
      end
    | VPrimitive (_, f) -> f memory v2
    | _ -> failwith "ill_typed apply"
  end

and apply_binop e1 v2 environment memory =
  match Position.value e1 with
  | Apply(var, e2') ->
    begin
      match var with
      | { value=Variable (id, None); position=pos } ->
        begin
          let v1 = expression' environment memory e2' in
          let f = Environment.lookup pos (Position.value id) primitives in
          match f with
          | VPrimitive (_, f) -> f memory (VTuple [v1;v2])
          | _ -> raise NotBinopApply
        end
      | _ -> raise NotBinopApply
    end
  | _ -> raise NotBinopApply

(** This function returns the difference between two runtimes. *)
and extract_observable runtime runtime' =
  let rec substract new_environment env env' =
    if env == env' then new_environment
    else
      match Environment.last env' with
        | None -> assert false (* Absurd. *)
        | Some (x, v, env') ->
          let new_environment = Environment.bind new_environment x v in
          substract new_environment env env'
  in
  {
    new_environment =
      substract Environment.empty runtime.environment runtime'.environment;
    new_memory =
      runtime'.memory
  }

(** This function displays a difference between two runtimes. *)
let print_observable runtime observation =
  Environment.print observation.new_memory observation.new_environment
