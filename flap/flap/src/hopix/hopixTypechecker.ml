(** This module implements a type checker for Hopix. *)
open HopixAST
open HopixTypes
open HopixPrettyPrinter

let initial_typing_environment = HopixTypes.initial_typing_environment

type typing_environment = HopixTypes.typing_environment

let type_error = HopixTypes.type_error

let located f x = f (Position.position x) (Position.value x)

(** [check_program_is_fully_annotated ast] performs a syntactic check
 that the programmer wrote sufficient type annotations for [typecheck]
 to run correctly. *)
let check_program_is_fully_annotated ast =
  (**
      We check the presence of type ascriptions on:
      - variables
      - tagged values patterns
   *)
  let rec program p = List.iter (located definition) p

  and definition pos = function
    | DefineValue vdef ->
      value_definition vdef
    | _ ->
      ()

  and value_definition = function
    (** A toplevel definition for a value. *)
    | SimpleValue (x, s, e) ->
       if s = None then missing_type_annotation (Position.position x);
       located expression e
    (** A toplevel definition for mutually recursive functions. *)
    | RecFunctions fs ->
       List.iter function_definition fs

  and function_definition = function
    | (f, s, FunctionDefinition (xs, e)) ->
       if s = None then missing_type_annotation (Position.position f);
       located expression e

  and expression pos = function
    | Define (vdef, e) ->
       value_definition vdef;
       located expression e
    | Apply (a, b) ->
       List.iter (located expression) [a; b]
    | Tuple ts ->
       List.iter (located expression) ts
    | Record (fields, a) ->
       if a = None then type_error pos "A type annotation is missing.";
       List.iter (fun (_, e) -> located expression e) fields
    | TypeAnnotation ({ Position.value = Fun (FunctionDefinition (xs, e)) },
                      _) ->
       located expression e
    | Fun (FunctionDefinition (_, _)) ->
       type_error pos "An anonymous function must be annotated."
    | Field (e, _) | TypeAnnotation (e, _) | Ref e | Read e ->
       located expression e
    | Sequence es ->
       List.iter (located expression) es
    | Tagged (_, a, es) ->
       if a = None then type_error pos "A type annotation is missing.";
       List.iter (located expression) es
    | For (_, e1, e2, e3) ->
       List.iter (located expression) (
           [ e1; e2; e2 ]
         )
    | IfThenElse (c, t, f) ->
       List.iter (located expression) [c; t; f]
    | Case (e, bs) ->
      located expression e;
      List.iter (located branch) bs
    | Assign (e1, e2) | While (e1, e2) ->
      located expression e1;
      located expression e2
    | Literal _ | Variable _ ->
      ()
  and pattern pos = function
    | PTypeAnnotation ({ Position.value = (PWildcard | PVariable _) }, _) ->
      ()
    | PRecord (fields, a) ->
       if a = None then type_error pos "A type annotation is missing.";
       List.iter (fun (_, p) -> located pattern p) fields
    | PTuple ps ->
       List.iter (located pattern) ps
    | PTypeAnnotation (p, _) ->
      located pattern p
    | PVariable _  ->
      missing_type_annotation pos
    | PTaggedValue (_, a, ps) ->
       if a = None then type_error pos "A type annotation is missing.";
       List.iter (located pattern) ps
    | POr ps | PAnd ps ->
      List.iter (located pattern) ps
    | PLiteral _ | PWildcard -> (* don't need type_annotation for wildcard *)
      ()
  and branch pos = function
    | Branch (p, e) ->
      located pattern p;
      located expression e
  and missing_type_annotation pos =
    type_error pos "A type annotation is missing."
  in
  program ast

let invalid_instantiation pos given expected =
  type_error pos (
      Printf.sprintf
        "Invalid number of types in instantiation: \
         %d given while %d were expected." given expected
    )

(** [typecheck tenv ast] checks that [ast] is a well-formed program
    under the typing environment [tenv]. *)
let typecheck tenv ast : typing_environment =
  check_program_is_fully_annotated ast;

  let rec program p =
    List.fold_left (fun env x -> located (definition env) x) tenv p

  and definition tenv pos = function
    | DefineValue vdef ->
       value_definition tenv vdef

    | DefineType (t, ts, tdef) ->
       let ts = List.map Position.value ts in
       HopixTypes.bind_type_definition (Position.value t) ts tenv tdef

    | DeclareExtern (x, s) ->
       let s = located (type_scheme tenv) s in
       bind_value (Position.value x) s tenv

  and type_scheme tenv pos (ForallTy (ts, ty)) =
    let ts = List.map Position.value ts in
    let tenv = bind_type_variables pos tenv ts in
    Scheme (ts, internalize_ty tenv ty)

  and bind_type_variables pos tenv ts =
    List.iter (fun v ->
        if HopixTypes.is_type_variable_defined pos tenv v then
          type_error pos (
              Printf.sprintf
                "The type variable `%s' is already bound in the environment."
                (HopixPrettyPrinter.(to_string type_variable v))
            )
      ) ts;
    HopixTypes.bind_type_variables pos tenv ts

  and value_definition (tenv : typing_environment) = function
    | SimpleValue (x, Some s, e) ->
       let pos = Position.position s in
       let Scheme (ts, aty) as s = located (type_scheme tenv) s in
       let tenv' = bind_type_variables pos tenv ts in
       check_expression_monotype tenv' aty e;
       bind_value (Position.value x) s tenv

    | SimpleValue (_, _, _) ->
       assert false (* By check_program_is_fully_annotated. *)

    | RecFunctions fs ->
       recursive_definitions tenv fs

  and recursive_definitions tenv recdefs =
    let tenv =
      List.fold_left (fun tenv (f, fs, d) ->
          match fs with
          | None ->
             assert false  (* By check_program_is_fully_annotated. *)
          | Some fs ->
             let f = Position.value f in
             let fs = located (type_scheme tenv) fs in
             let fs = refresh_type_scheme fs in
             bind_value f fs tenv
        ) tenv recdefs
    in
    List.iter (fun (f, fs, d) ->
        match fs with
        | None ->
           assert false
        | Some fs ->
           let pos = Position.position f in
           let fs = located (type_scheme tenv) fs in
           check_function_definition pos tenv fs d
      ) recdefs;
    tenv

  (** [check_function_definition tenv fdef] checks that the
      function definition [fdef] is well-typed with respect to the
      type annotations written by the programmer. We assume that
      [tenv] already contains the type scheme of the function [f]
      defined by [fdef] as well as all the functions which are
      mutually recursively defined with [f]. *)
  and check_function_definition pos tenv aty = function
    | FunctionDefinition (p, e) ->
       match aty with
       | Scheme (ts, ATyArrow (xty, out)) ->
          let tenv = bind_type_variables pos tenv ts in
          let tenv, _ = located (pattern tenv) p in
          check_expression_monotype tenv out e
       | _ ->
          type_error pos "A function must have an arrow type."

  (** [check_expected_type pos xty ity] verifies that the expected
      type [xty] is syntactically equal to the inferred type [ity]
      and raises an error otherwise. *)
  and check_expected_type pos xty ity =
    if xty <> ity then
      type_error pos (
          Printf.sprintf "Type error:\nExpected:\n  %s\nGiven:\n  %s\n"
            (print_aty xty) (print_aty ity)
        )

  (** [check_expression_monotype tenv xty e] checks if [e] has
      the monotype [xty] under the context [tenv]. *)
  and check_expression_monotype tenv xty e : unit =
    let pos = Position.position e in
    let ity = located (type_of_expression tenv) e in
    check_expected_type pos xty ity

  (** [type_of_expression tenv pos e] computes a type for [e] if it exists. *)
  and type_of_expression tenv pos : expression -> aty = function
  | Literal x ->  literal (Position.value x)
  | Variable (id, _) -> variable tenv pos (Position.value id)
  | Tagged (cons, Some tys, exprs) -> tagged tenv pos cons tys exprs
  | Record (label_expr_list, Some ty_l) -> record tenv pos label_expr_list ty_l
  | Field (e, l) -> field tenv pos e l
  | Tuple l -> tuple tenv pos l
  | Sequence l -> sequence tenv pos l
  | Define (vdef, e) -> define tenv pos vdef e
  | Fun fd -> fun_ tenv pos fd
  | Apply (e1, e2) -> apply tenv pos e1 e2
  | Ref e -> ref_ tenv pos e
  | Assign (e1, e2) -> assign tenv pos e1 e2
  | Read e -> read tenv pos e
  | Case (e, branchs) -> case tenv pos e branchs
  | IfThenElse (e1, e2, e3) -> ifthenelse tenv pos e1 e2 e3
  | While (e1, e2) -> while_ tenv pos e1 e2
  | For (id, e1, e2, e3) -> for_ tenv pos e1 e2 e3
  | TypeAnnotation (e, ty) -> typeannotation tenv pos e ty
  | _ -> assert false

  and literal = function
  | LInt _ -> hint
  | LString _ -> hstring
  | LChar _ -> hchar

  and variable tenv pos id =
    try
      match lookup_type_scheme_of_value pos id tenv with
      | Scheme ([], aty)-> aty
      | Scheme (_, aty) -> aty
    with UnboundIdentifier (pos, id) ->
      let Id id = id in
      type_error pos (
        "Unbound variable " ^ id
      )

  and raise_unboundtagged pos name =
    let _ = type_error pos (
      "Unbound tagged type `" ^ name ^ "`"
    ) in
    assert false

  and tagged tenv pos cons tys_annot exprs =
    let rec get_types_variables ty index_ty_annot tys_annot types_variables types =
      match ty with
      | ATyArrow (ATyVar tv as t', t) ->
        (* On ajoute dans tys_variables, le type annoté associé au type variable *)
        let ty_real = aty_of_ty (Position.value (List.nth tys_annot index_ty_annot)) in
        get_types_variables t (index_ty_annot+1) tys_annot ( (tv, ty_real)::types_variables ) (t'::types)
      | ATyArrow (t, t') ->
        get_types_variables t' (index_ty_annot) tys_annot types_variables (t::types)
      | t -> t, types_variables, types
    in
    let rec check_types types exprs types_variables =
      (* vérifier que chaque types = exprs dans l'env types_variables *)
      match types, exprs with
      | [], [] -> () (* fini *)
      | t::ts, e::es ->
          let t = match t with
          | ATyVar x ->
            begin
              try
                List.assoc x types_variables
              with Not_found -> assert false (* type variable est pas annoté *)
            end
          | t -> t
          in
          let texpr = type_of_expression tenv pos (Position.value e) in
          check_expected_type e.position t texpr;
          check_types ts es types_variables
      | _ -> assert false
    in
    try
      (* lis contient les types variables du constructeur *)
      let Scheme (lis, ty) = lookup_type_scheme_of_constructor (Position.value cons) tenv in

      (* on recupère les vrais types des types_variables via les annotations *)
      let (t, types_variables, types) = get_types_variables ty 0 tys_annot [] [] in

      (* on vérifie que chaque membre du type est bien annoté et a le même type que le tagged *)
      let name = match t with | ATyCon (TCon name, _) -> name | _ -> assert false in
      check_types types exprs types_variables;
      ATyCon (TCon name, (List.map (fun x -> aty_of_ty (Position.value x)) tys_annot));
    with
      UnboundConstructor ->
        let KId name = Position.value cons in raise_unboundtagged cons.position name

  and raise_unboundfield pos name =
    type_error pos ("Unbound record field `" ^ name ^ "`")

  and lab_tostr l = match Position.value l with
  | LId x -> x

  and get_ty_with_types_variables scheme tys_variables tys_annots (index_ty_annot:int) =
    match scheme with
    | Scheme(lis, ty) ->
      let ty = match ty with | ATyArrow (_, ty) -> ty | _ -> assert false in
      match lis with
      | [] -> ty, tys_variables, index_ty_annot (* si on est ici, c'est qu'il n'y a pas de types variables dans le scheme *)
      | lis ->
        match ty with
        | ATyVar _ as x -> (* le label que nous traitons a un type_variable *)
          begin
            try
              let ty = List.assoc x tys_variables in
              (ty, tys_variables, index_ty_annot) (* si on a déjà le type de type_variable, on le recupère dans tys_variables *)
            with
            | Not_found ->
              let ty_of_annot = List.nth tys_annots index_ty_annot in
              let ty_of_annot = aty_of_ty (Position.value ty_of_annot) in
              (ty_of_annot, ( (x, ty_of_annot)::tys_variables ), (index_ty_annot+1))
              (* sinon on ajoute a tys_variables le type associé au type variable, lu dans les types annotations *)
          end
        | _ -> (ty, tys_variables, index_ty_annot) (* ce n'est pas un type variable, on reprend juste son type *)

  and record_aux tenv pos labels_exprs labels tys_variables tys_annots index_ty_annot=
    match labels_exprs, labels with
    | (l, e)::s, l'::s' ->
        (* on vérifie que les labels sont exacts *)
        if (lab_tostr l)<>l' then raise_unboundfield l.position (lab_tostr l) else

        (* on recupère le type du label *)
        let scheme = lookup_type_scheme_of_label (Position.value l) tenv in
        let (ty_of_record, tys_variables, index_ty_annot) = get_ty_with_types_variables scheme tys_variables tys_annots index_ty_annot in

        (* recupère le type de l'expression *)
        let ty_of_expr = type_of_expression tenv pos (Position.value e) in

        (* on vérifie que l'expression et le label correspondent *)
        check_expected_type e.position ty_of_record ty_of_expr; (* expression type match record type *)
        record_aux tenv pos s s' tys_variables tys_annots index_ty_annot
    | [], [] -> ()
    | _ -> assert false

  and record tenv pos labs_exprs ty_l =
    let hd_label = fst (List.hd labs_exprs) in
    try
      (* on récupère le record avec le label *)
      let (name, arity, labels_record) = lookup_type_constructor_of_label (Position.value hd_label) tenv in
      (* on vérifie qu'il a assez d'élements, et assez d'annotations *)
      if List.length labels_record <> List.length labs_exprs then (type_error pos ("Some record fields are undefined")) else
      if arity > List.length ty_l then (type_error pos ("Some `a fields doesn't have type annotation")) else


      (* on la trie en fonction des labels *)
      let labels_exprs = List.sort (fun (x,_) (y,_) -> let x = lab_tostr x in let y = lab_tostr y in if x=y then 0 else if x>y then 1 else -1) labs_exprs in
      let labels_record = List.sort (fun x y -> if x=y then 0 else if x>y then 1 else -1) labels_record in

      (* record_aux fait les test de types sur tous les labels *)
      record_aux tenv pos labels_exprs (List.map (fun x -> let LId x = x in x) labels_record) [] ty_l 0;
      ATyCon (name, (List.map (fun x -> aty_of_ty (Position.value x)) ty_l));
    with
    | UnboundLabel -> let _ = raise_unboundfield hd_label.position (lab_tostr hd_label) in assert false;

  and field tenv pos e l =
    let raise_unboundfield pos name =
      type_error pos (
        "Unbound record field `" ^ name ^"`"
      )
    in
    try
      let (name, arity, labels) = lookup_type_constructor_of_label (Position.value l) tenv in
      let t = type_of_expression tenv e.position (Position.value e) in
      let name' = match t with | ATyCon (name', _) -> name' | _ -> assert false in
      let TCon name' = name' in
      let TCon name = name in
      if name <> name' then (
        type_error e.position (
          name' ^ " is not a record " ^ name
        )
      )
      else (
        let scheme = lookup_type_scheme_of_label (Position.value l) tenv in
        let ty_of_record = match type_of_monotype scheme with | ATyArrow (_, ty_of_record) -> ty_of_record | _ -> assert false in
        ty_of_record
      )
    with UnboundLabel ->
      let LId name = Position.value l in raise_unboundfield l.position name
  and tuple tenv pos l =
      hprod (List.map (fun x -> type_of_expression tenv pos x) (List.map (fun x -> Position.value x) l))

  and sequence tenv pos = function
  | e1::e2::[] ->
    let t_e1 = type_of_expression tenv e1.position (Position.value e1) in
    let t_e2 = type_of_expression tenv e2.position (Position.value e2) in
    check_expected_type e1.position t_e1 hunit;
    t_e2
  | _ -> assert false

  and define tenv pos vdef e =
      let tenv' = value_definition tenv vdef in
      type_of_expression tenv' pos (Position.value e)

  and fun_ tenv pos = function
  | FunctionDefinition (p, e) ->
      let tenv', tp = pattern tenv p.position (Position.value p) in
      let t = type_of_expression tenv' e.position (Position.value e) in
      ATyArrow (tp, t)

  and apply tenv pos f e =
    let f' = type_of_expression tenv f.position (Position.value f) in
    match f' with
    | ATyArrow (from, to') ->
      let t = type_of_expression tenv e.position (Position.value e) in
      check_expected_type e.position from t;
      to'
    | _ ->
      type_error f.position (
        (print_aty f') ^ " is not a function, it cannot be applied\n"
      )

  and ref_ tenv pos e =
      let t = type_of_expression tenv e.position (Position.value e) in
      href t

  and assign tenv pos e1 e2 =
    let t_e1 = type_of_expression tenv e1.position (Position.value e1) in
    let t_e2 = type_of_expression tenv e2.position (Position.value e2) in
    match t_e1 with
    | ATyCon (_, [t]) ->
      check_expected_type e1.position t t_e2;
      hunit
    | _ ->
      type_error e1.position (
        "This expression has type " ^ print_aty t_e1 ^ ", this is not a reference"
      )

  and read tenv pos e =
      let t = type_of_expression tenv e.position (Position.value e) in
      try type_of_reference_type t
      with NotAReference ->
      type_error e.position (
        "This expression has type " ^ print_aty t ^ ", this is not a reference"
      )

  and case tenv pos e branchs =
      let t_matched = type_of_expression tenv e.position (Position.value e) in
      let Branch (p_supposed, e_supposed) = Position.value (List.hd branchs) in
      let (p_env, _) = pattern tenv pos (Position.value p_supposed) in
      let t = type_of_expression p_env e_supposed.position (Position.value e_supposed) in

      (* raise error if pattern doesn't match expr *)
      let rec error pos t p =
        type_error pos (
          Printf.sprintf "Error: pattern %s does not match expression %s\n"
            (print_aty p) (print_aty t)
        )
      in
      (* check if every pattern matchs e type, and expression matchs t_supposed type *)
      let rec aux branchs = match branchs with
      | Branch(p, e)::bs ->
        let pat_tenv, pat_t = pattern tenv p.position (Position.value p) in
        (* check pattern type equals t_matched *)
        let pat_t = if pat_t = ATyVar (TId "`a") then t_matched else pat_t in
        if pat_t <> t_matched then error pos t_matched pat_t else
        let e_t = type_of_expression pat_tenv e.position (Position.value e) in
        check_expected_type e.position t e_t;
        aux bs
      | [] -> t

      in
      aux (List.map (fun x -> Position.value x) branchs)

  and ifthenelse tenv pos e1 e2 e3 =
      let t_e1 = type_of_expression tenv e1.position (Position.value e1) in
      let t_e2 = type_of_expression tenv e2.position (Position.value e2) in
      let t_e3 = type_of_expression tenv e2.position (Position.value e3) in
      check_expected_type e1.position t_e1 hbool;
      check_expected_type e2.position t_e2 t_e3;
      t_e2

  and while_ tenv pos e1 e2 =
      let t_e1 = type_of_expression tenv e1.position (Position.value e1) in
      let t_e2 = type_of_expression tenv e2.position (Position.value e2) in
      check_expected_type e1.position t_e1 hbool;
      check_expected_type e2.position t_e2 hunit;
      hunit

  and for_ tenv pos e1 e2 e3 =
    let t_e1 = type_of_expression tenv e1.position (Position.value e1) in
    let t_e2 = type_of_expression tenv e2.position (Position.value e2) in
    let t_e3 = type_of_expression tenv e3.position (Position.value e3) in
    check_expected_type e1.position t_e1 hint;
    check_expected_type e2.position t_e2 hint;
    check_expected_type e3.position t_e3 hunit;
    hunit

  and typeannotation tenv pos e t =
      let t_e = type_of_expression tenv e.position (Position.value e) in
      check_expected_type e.position t_e (aty_of_ty (Position.value t));
      t_e

  and patterns tenv = function
    | [] ->
       tenv, []
    | p :: ps ->
       let tenv, ty = located (pattern tenv) p in
       let tenv, tys = patterns tenv ps in
       tenv, ty :: tys

  (** [pattern tenv pos p] computes a new environment completed with
      the variables introduced by the pattern [p] as well as the type
      of this pattern. *)
  and pattern tenv pos = function
    | PVariable id -> assert false (* can not happens *)
    | PWildcard -> (tenv, tvar "`a")
    | PTypeAnnotation (p, ty) ->
      let ty = aty_of_ty (Position.value ty) in
      begin match (Position.value p) with
        | PVariable id ->
          let test = bind_value (Position.value id) (monotype ty) tenv in
          test, ty
        | _ ->
          let tenv', ty' = pattern tenv pos (Position.value p) in
          let ty' = if ty' = ATyVar (TId "`a") then ty else ty' in
          check_expected_type pos ty ty';
          (tenv', ty)
      end
    | PTaggedValue (cons, Some tys, ps) -> ptagged tenv pos cons tys ps
    | PLiteral l ->
      let t = literal (Position.value l) in
      (tenv, t)
    | PRecord (labs_pats, Some tys) -> precord tenv pos labs_pats tys
    | PTuple ps ->
      let tenv', ps = patterns tenv ps in
      (tenv', ATyTuple ps)
    | POr ps | PAnd ps -> pandor tenv pos ps
    | _ -> assert false

  and ptagged tenv pos cons tys_annot ps =
    let rec get_types_variables ty index_ty_annot tys_annot types_variables types =
      match ty with
      | ATyArrow (ATyVar tv as t', t) ->
        (* On ajoute dans tys_variables, le type annoté associé au type variable *)
        let ty_real = aty_of_ty (Position.value (List.nth tys_annot index_ty_annot)) in
        get_types_variables t (index_ty_annot+1) tys_annot ( (tv, ty_real)::types_variables ) (t'::types)
      | ATyArrow (t, t') ->
        get_types_variables t' (index_ty_annot) tys_annot types_variables (t::types)
      | t -> t, types_variables, types
    in
    let rec check_types tenv' types pats types_variables =
      (* vérifier que chaque types = pats dans l'env types_variables *)
      match types, pats with
      | [], [] -> tenv' (* fini *)
      | t::ts, p::ps ->
          let t = match t with
          | ATyVar x ->
            begin
              try
                List.assoc x types_variables
              with Not_found -> assert false (* type variable est pas annoté *)
            end
          | t -> t
          in
          let (tenv', p_type) = pattern tenv' pos (Position.value p) in
          check_expected_type p.position t p_type;
          check_types tenv' ts ps types_variables
      | _ -> assert false
    in
    try
      (* lis contient les types variables du constructeur *)
      let Scheme (lis, ty) = lookup_type_scheme_of_constructor (Position.value cons) tenv in

      (* on recupère les vrais types des types_variables via les annotations *)
      let (t, types_variables, types) = get_types_variables ty 0 tys_annot [] [] in

      (* on vérifie que chaque membre du type est bien annoté et a le même type que le tagged *)
      let name = match t with | ATyCon (TCon name, _) -> name | _ -> assert false in
      let env = check_types tenv types ps types_variables in
      (env, ATyCon (TCon name, (List.map (fun x -> aty_of_ty (Position.value x)) tys_annot)))
    with
      UnboundConstructor ->
        let KId name = Position.value cons in let _ = raise_unboundtagged cons.position name in assert false

  and precord_aux tenv' pos labels_pats labels_record tys_variables tys_annots index_ty_annot =
    match labels_pats, labels_record with
    | (l, p)::s, l'::s' ->
      (* on vérifie que les labels sont égaux, comme on a trié ils correspondent *)
      if (lab_tostr l)<>l' then type_error l.position ("Unbound record field `" ^ (lab_tostr l) ^ "`") else


      (* On recupère le type du label *)
      let scheme = lookup_type_scheme_of_label (Position.value l) tenv' in
      let (ty_of_record, tys_variables, index_ty_annot) = get_ty_with_types_variables scheme tys_variables tys_annots index_ty_annot in

      (* on récupère le type du pattern *)
      let tenv', ty_of_pat = pattern tenv' pos (Position.value p) in

      (* si le pattern est `a, on lui affecte le type annoté *)
      let ty_of_pat = match ty_of_pat with | ATyVar (TId "`a") -> ty_of_record | t -> t in

      (* on vérifie que les types correspondent, si pas de probleme, on passe a la suite *)
      check_expected_type p.position ty_of_record ty_of_pat;
      precord_aux tenv' pos s s' tys_variables tys_annots index_ty_annot
    | [], [] -> tenv'
    | _ -> assert false

  and precord tenv pos labs_pats tys =
    let hd_label = fst (List.hd labs_pats) in
    try
      let (name, arity, labels_record) = lookup_type_constructor_of_label (Position.value hd_label) tenv in
      (* on vérifie qu'on a assez de labels dans le record, et assez d'annotations *)
      if List.length labels_record <> List.length labs_pats then (type_error pos ("Some record fields are undefined")) else
      if arity > List.length tys then (type_error pos ("Some `a fields doesn't have type annotation")) else

      (* on trie la liste en fonction des labels *)
      let labels_pats = List.sort (fun (x,_) (y,_) -> let x = lab_tostr x in let y = lab_tostr y in if x=y then 0 else if x>y then 1 else -1) labs_pats in
      (* on trie les records du type en fonction des labels *)
      let labels_record = List.sort (fun x y -> if x=y then 0 else if x>y then 1 else -1) labels_record in

      (* appel a precord aux *)
      let tenv' = precord_aux tenv pos labels_pats (List.map (fun x -> let LId x = x in x) labels_record) [] tys 0 in

      (tenv', ATyCon (name, (List.map (fun x -> aty_of_ty (Position.value x)) tys)));
    with
    | UnboundLabel -> type_error hd_label.position ("Unbound record field `" ^ (lab_tostr hd_label) ^ "`")

  and pandor tenv pos ps =
    let tenv', ps = patterns tenv ps in
    let rec error_and pos ty ty' =
      if ty <> ty' then
        type_error pos (
          (print_aty ty') ^ " not compatible of " ^ (print_aty ty)
        )
    in
    let t = List.hd ps in
    List.iter (fun t' -> error_and pos t t') ps;
    (tenv', t)

  in
  program ast


let print_typing_environment = HopixTypes.print_typing_environment
