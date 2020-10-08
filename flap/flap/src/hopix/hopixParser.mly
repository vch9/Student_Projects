%{ (* -*- tuareg -*- *)

  open HopixAST
  open Position

  (* Convert binop to string *)
  let bop_to_string = function
  | PLUS -> "`+`"
  | MINUS -> "`-`"
  | TIMES -> "`*`"
  | DIV -> "`/`"
  | B_AND -> "`&&`"
  | B_OR -> "`||`"
  | B_EQUAL -> "`=?`"
  | LEQUAL -> "`<=?`"
  | MEQUAL -> "`>=?`"
  | LESS -> "`<?`"
  | MORE -> "`>?`"
  | _ -> failwith "wrong binop"

  (* Build apply with infix notation *)
  let build_apply_binop e1 e2 op_pos op = match op_pos with
  | (_, startpos, endpos) ->
      let make_located x =
        Position.with_poss startpos endpos x
      in
        Apply (
          make_located( Apply (
            make_located ( Variable (make_located (Id (bop_to_string op)), None)),
            e1
          )),
          e2
        )

  (* Create while located *)
  let create_while e1 e2 pos = match pos with
  | (_, startpos, endpos) ->
    let make_located x =
      Position.with_poss startpos endpos x
    in make_located (While (e1, e2))

%}

%token<int64> INT
%token<char> CHAR
%token<string> STRING TYPE_VAR CONSTR_ID ID


(* token syntax *)
%token COLON SEMICOLON
%token LCHEV RCHEV
%token LBRACKET RBRACKET
%token OBRACE CBRACE
%token LPAR RPAR
%token OR AND DOT

%token EXTERN LET
%token TYPE EOF EQUAL COMMA RARROW  UNDERSCORE FUN

(* token binop *)
%token PLUS MINUS TIMES DIV B_AND B_OR B_EQUAL LEQUAL MEQUAL LESS MORE

(* token exr *)
%token BACKSLASH EXCLA ASSIGN REF SWITCH IF ELSE WHILE DO FOR IN TO

(* priority *)
%left B_EQUAL
%left LEQUAL
%left MEQUAL
%left LESS
%left MORE
%left B_OR
%left B_AND

%left PLUS MINUS
%left TIMES DIV

%left COLON

%left ASSIGN

%right RARROW

%right SEMICOLON

%left vdef

%start<HopixAST.t> program

%%

program:
| l=list(located(definition)) EOF
{ l }

(** ------------------------------------------------------- DEFINITION ------------------------------------------------------- **)
definition: TYPE tc=located(type_constructor) tp_v=loption(delimited(LCHEV, separated_list(COMMA, located(type_variable)),RCHEV))
{ DefineType (tc, tp_v, Abstract) }
| TYPE tc=located(type_constructor) tp_v=loption(delimited(LCHEV, separated_list(COMMA, located(type_variable)),RCHEV)) EQUAL td=tdefinition
{ DefineType (tc, tp_v, td) }
| EXTERN v=located(identifier) COLON tp_s=located(ty_scheme)
{ DeclareExtern (v, tp_s) }
| v=vdefinition
{ DefineValue (v) }
(** ------------------------------------------------------- /DEFINITION ------------------------------------------------------- **)

(** ------------------------------------------------------- TYPE_DEFINITION ------------------------------------------------------- **)
tdefinition: option(OR) c=located(constructor) types=loption(delimited(LPAR, separated_nonempty_list(COMMA, located(ty)),RPAR)) suite=tdefinition_aux
{ DefineSumType ((c, types)::suite) }
| OBRACE l=separated_nonempty_list(COMMA, label_colon_ty) CBRACE
{ DefineRecordType (l) }

label_colon_ty: lab=located(label) COLON t=located(ty)
{ (lab, t) }

tdefinition_aux:
| { [] }
| OR c=located(constructor) types=loption(delimited(LPAR, separated_nonempty_list(COMMA, located(ty)),RPAR)) suite=tdefinition_aux
{ (c, types)::suite }

(** ------------------------------------------------------- /TYPE_DEFINITION ------------------------------------------------------- **)

(** ------------------------------------------------------- VALUE DEFINITION ------------------------------------------------------- **)
vdefinition:
| LET v=located(identifier) EQUAL e=located(expr)
{ SimpleValue (v, None, e) }
| LET v=located(identifier) COLON ty_sc=located(ty_scheme) EQUAL e=located(expr)
{ SimpleValue (v, Some ty_sc, e) }
| FUN f=fundef l=fun_rec
{ RecFunctions (f::l) }

vdefinition_semi:
| LET v=located(identifier) EQUAL e=located(expr) %prec vdef
{ SimpleValue (v, None, e) }
| LET v=located(identifier) COLON ty_sc=located(ty_scheme) EQUAL e=located(expr) %prec vdef
{ SimpleValue (v, Some ty_sc, e) }
| FUN f=fundef_semi l=fun_rec_semi
{ RecFunctions (f::l) }

fun_rec:
| { [] }
| AND f=fundef l=fun_rec
{ f::l }

fun_rec_semi:
| { [] }
| AND f=fundef_semi l=fun_rec_semi
{ f::l }
(** ------------------------------------------------------- /VALUE DEFINITION ------------------------------------------------------- **)

(** ------------------------------------------------------- fundef ------------------------------------------------------- **)
fundef: COLON typ_s=located(ty_scheme) id=located(identifier) p=located(pattern) EQUAL e=located(expr)
{ (id, Some typ_s, FunctionDefinition (p, e)) }
| id=located(identifier) p=located(pattern) EQUAL e=located(expr)
{ (id, None, FunctionDefinition (p, e)) }

fundef_semi: COLON typ_s=located(ty_scheme) id=located(identifier) p=located(pattern) EQUAL e=located(expr) %prec vdef
{ (id, Some typ_s, FunctionDefinition (p, e)) }
| id=located(identifier) p=located(pattern) EQUAL e=located(expr) %prec vdef
{ (id, None, FunctionDefinition (p, e)) }
(** ------------------------------------------------------- /fundef ------------------------------------------------------- **)

(** ------------------------------------------------------- EXPRESSION ------------------------------------------------------- **)

expr_binop:
| e1=located(expr_binop) b=start_end_pos(TIMES) e2=located(expr_binop)
{ build_apply_binop e1 e2 b TIMES }
| e1=located(expr_binop) b=start_end_pos(DIV) e2=located(expr_binop)
{ build_apply_binop e1 e2 b DIV }
| e1=located(expr_binop) b=start_end_pos(PLUS) e2=located(expr_binop)
{ build_apply_binop e1 e2 b PLUS }
| e1=located(expr_binop) b=start_end_pos(MINUS) e2=located(expr_binop)
{ build_apply_binop e1 e2 b MINUS }
| e1=located(expr_binop) b=start_end_pos(B_EQUAL) e2=located(expr_binop)
{ build_apply_binop e1 e2 b B_EQUAL }
| e1=located(expr_binop) b=start_end_pos(LEQUAL) e2=located(expr_binop)
{ build_apply_binop e1 e2 b LEQUAL }
| e1=located(expr_binop) b=start_end_pos(MEQUAL) e2=located(expr_binop)
{ build_apply_binop e1 e2 b MEQUAL }
| e1=located(expr_binop) b=start_end_pos(B_AND) e2=located(expr_binop)
{ build_apply_binop e1 e2 b B_AND }
| e1=located(expr_binop) b=start_end_pos(B_OR) e2=located(expr_binop)
{ build_apply_binop e1 e2 b B_OR }
| e1=located(expr_binop) b=start_end_pos(LESS) e2=located(expr_binop)
{ build_apply_binop e1 e2 b LESS }
| e1=located(expr_binop) b=start_end_pos(MORE) e2=located(expr_binop)
{ build_apply_binop e1 e2 b MORE }
| e=expr_apply
{ e }

expr:
| e1=located(expr) SEMICOLON e2=located(expr)
{ Sequence ([e1;e2]) }
| v=vdefinition_semi SEMICOLON e=located(expr)
{ Define (v,e) }
| BACKSLASH p=located(pattern) RARROW e=located(expr)
{ Fun (FunctionDefinition (p, e)) }
| e=expr_assign
{ e }

expr_assign:
| e1=located(expr_assign) ASSIGN e2=located(expr_assign)
{ Assign (e1, e2) }
| e=expr_binop
{ e }


(*
  expr produces a shift/reduce conflict over
  expr := constructor (expr..)
  menhir fix it by shifting the expression, building expression.Tagged over expression.apply
*)
expr_apply:
| e1=located(expr_apply) e2=located(expr_factor)
{ Apply (e1, e2) }
| e=expr_factor
{ e }


expr_factor:
| e=located(expr_factor) DOT l=located(label)
{ Field (e,l) }
| e=expr_term
{ e }

expr_term:
| constr=located(constructor) types=loption(delimited(LCHEV, separated_list(COMMA, located(ty)),RCHEV)) exprs=loption(delimited(LPAR, separated_nonempty_list(COMMA, located(expr)),RPAR))
{ Tagged (constr, Some types, exprs) }
| EXCLA e=located(expr_term)
{ Read e }
| REF e=located(expr_term)
{ Ref e }
| SWITCH LPAR e1=located(expr) RPAR OBRACE b=branches CBRACE
{ Case (e1, b) }
| IF LPAR e1=located(expr) RPAR OBRACE e2=located(expr) CBRACE ELSE OBRACE e3=located(expr) CBRACE
{ IfThenElse (e1, e2, e3) }
| WHILE LPAR e1=located(expr) RPAR OBRACE e2=located(expr) CBRACE
{ While (e1, e2) }
| FOR v=located(identifier) IN LPAR e1=located(expr) TO e2=located(expr) RPAR OBRACE e3=located(expr) CBRACE
{ For (v, e1, e2, e3) }
| DO OBRACE e1=located(expr) CBRACE pos=start_end_pos(WHILE) LPAR e2=located(expr) RPAR
{ Sequence ([e1; create_while e1 e2 pos]) }
| lis=delimited(OBRACE, separated_nonempty_list(COMMA, label_equal_expr) ,CBRACE)
{ Record (lis, None) }
| lis=delimited(OBRACE, separated_nonempty_list(COMMA, label_equal_expr) ,CBRACE) tys=delimited(LCHEV, separated_list(COMMA, located(ty)), RCHEV)
{ Record (lis, Some tys) }
| v=located(identifier) l=loption(delimited(LCHEV, separated_nonempty_list(COMMA, located(ty)), RCHEV))
{
  let types = match l with
  | [] -> None
  | _ -> Some l
  in Variable (v, types)
}
| e=expr_simple
{ e }

expr_simple:
| LPAR e1=located(expr) COLON t=located(ty) RPAR
{ TypeAnnotation (e1, t) }
| LPAR e=located(expr) COMMA l=separated_nonempty_list(COMMA, located(expr)) RPAR
{ Tuple (e::l) }
| l=located(literal)
{ Literal l }
| LPAR e=expr RPAR
{ e }

label_equal_expr: l=located(label) EQUAL e=located(expr)
{ (l, e) }
(** ------------------------------------------------------- /EXPRESSION ------------------------------------------------------- **)


(** ------------------------------------------------------- PATTERN ------------------------------------------------------- **)
pattern:
| p=pattern_and
{ p }

pattern_and:
| p=located(pattern_or) AND p2=separated_nonempty_list(AND, located(pattern_or))
{ PAnd (p::p2) }
| p=pattern_or
{ p }

pattern_or:
| p=located(pattern_colon) OR p2=separated_nonempty_list(OR, located(pattern_colon))
{ POr (p::p2) }
| p=pattern_colon
{ p }

pattern_colon:
| p=located(pattern_term) COLON t=located(ty)
{ PTypeAnnotation (p, t) }
| p=pattern_term
{ p }


pattern_term:
| i=located(identifier)
{ PVariable i }
| UNDERSCORE
{ PWildcard }
| l=located(literal)
{ PLiteral l }
| LPAR p=located(pattern) COMMA p2=separated_nonempty_list(COMMA, located(pattern)) RPAR
{ PTuple (p::p2) }
| lis=delimited(OBRACE, separated_nonempty_list(COMMA, label_equal_pattern), CBRACE) types=loption(delimited(LCHEV, separated_list(COMMA, located(ty)), RCHEV))
{
  let t = match types with
  | [] -> None
  | h::t -> Some types
  in PRecord (lis, t)
}
| c=located(constructor) types=loption(delimited(LCHEV, separated_list(COMMA, located(ty)),RCHEV) ) pats=loption(delimited(LPAR, separated_nonempty_list(COMMA, located(pattern)), RPAR))
{
  let t = match types with
  | [] -> None
  | h::t -> Some types
  in PTaggedValue (c, t, pats)
}
| LPAR p=pattern RPAR
{ p }



label_equal_pattern: lab=located(label) EQUAL p=located(pattern)
{ (lab, p) }


(** ------------------------------------------------------- /PATTERN ------------------------------------------------------ **)


(** ------------------------------------------------------- BRANCHES -------------------------------------------------------**)
branches: option(OR) l=separated_nonempty_list(OR, located(branch))
{ l }
(** ------------------------------------------------------- /BRANCHES ------------------------------------------------------- **)

(** ------------------------------------------------------- BRANCHE ------------------------------------------------------- **)
branch: p=located(pattern) RARROW e=located(expr)
{ Branch (p, e) }
(** ------------------------------------------------------- /BRANCHE ------------------------------------------------------- **)

(** ------------------------------------------------------- TYPE ------------------------------------------------------- **)
ty:
| t=ty_term
{ t }
| t1=located(ty) RARROW t2=located(ty)
{ TyArrow (t1, t2) }
| t1=located(ty_term) TIMES l=separated_nonempty_list(TIMES, located(ty_term))
{ TyTuple (t1::l) }

ty_term:
| tv=type_variable
{ TyVar tv }
| tc=type_constructor l=loption(delimited(LCHEV, separated_list(COMMA, located(ty)), RCHEV))
{ TyCon (tc, l) }
| LPAR t=ty RPAR
{ t }
(** ------------------------------------------------------- /TYPE ------------------------------------------------------- **)

(** ------------------------------------------------------- TYPE_SCHEME ------------------------------------------------------- **)
ty_scheme: l=loption(delimited(LBRACKET, nonempty_list(located(type_variable)), RBRACKET)) t=located(ty)
{ ForallTy (l, t) }
(** ------------------------------------------------------- /TYPE_SCHEME ------------------------------------------------------- **)

(** ------------------------------------------------------- LITERAL ------------------------------------------------------- **)
literal: i=INT
{ LInt i }
| s=STRING
{ LString s }
| c=CHAR
{ LChar c }
(** ------------------------------------------------------- /LITERAL ------------------------------------------------------- **)

(** ------------------------------------------------------- IDENTIFIER ------------------------------------------------------- **)
identifier: i=ID
{ Id i }
(** ------------------------------------------------------- /IDENTIFIER ------------------------------------------------------- **)

(** ------------------------------------------------------- TYPE_CONSTRUCTOR ------------------------------------------------------- **)
type_constructor: s=ID
{ TCon s }
(** ------------------------------------------------------- /TYPE_CONSTRUCTOR ------------------------------------------------------- **)

(** ------------------------------------------------------- TYPE_VARIABLE ------------------------------------------------------- **)
type_variable: s=TYPE_VAR
{ TId s }
(** ------------------------------------------------------- /TYPE_VARIABLE ------------------------------------------------------- **)

(** ------------------------------------------------------- CONSTRUCTOR ------------------------------------------------------- **)
constructor: s=CONSTR_ID
{ KId s }
(** ------------------------------------------------------- /CONSTRUCTOR ------------------------------------------------------- **)

(** ------------------------------------------------------- LABEL ------------------------------------------------------- **)
label: i=ID
{ LId i }
(** ------------------------------------------------------- /LABEL ------------------------------------------------------- **)


%inline located(X): x=X {
  Position.with_poss $startpos $endpos x
}

%inline start_end_pos(X): x=X {
  (x, $startpos, $endpos)
}
