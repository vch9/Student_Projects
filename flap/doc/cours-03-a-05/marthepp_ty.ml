(** {1 Cours 04 : Marthe++} *)

(** {2 Syntaxe du langage jouet Marthe++} *)

(** Type des identifiants. *)
type identifier = string
;;

(** Type des opérateurs binaires. *)
type bop =
  | Add | Sub | Mul | Div
  | And | Or
  | Le

(** Type des opérateurs unaires. *)
type uop =
  | Not

(** Type (OCaml) des types (Mathe++) simples. *)
type ty =
  | TInt
  | TBool
  | TPair of ty * ty
  | TFun of ty * ty

(** Type des termes (expressions) du langage Marthe. *)
type term =
  | Id of identifier                (** variables *)
  | LInt of int                     (** constantes litérales entières *)
  | LBool of bool                   (** constantes littérales booléennes *)
  | Bop of bop * term * term        (** opération binaire *)
  | Uop of uop * term               (** opération unaire *)
  | Let of identifier * term * term (** définition locale *)
  | Pair of term * term             (** paires *)
  | Fst of term                     (** première projection *)
  | Snd of term                     (** seconde projection *)
  | If of term * term * term        (** conditionnelle *)
  | Fun of identifier * ty * term   (** fonction anonyme *)
  | App of term * term              (** application *)

(** Les différentes fonctions d'affichage utilisent le module
   {!module:Stdlib.Format}. On peut ordonner au toplevel d'utiliser la fonction
   d'affichage [f] via la directive [#install_printer f]. *)

(** [print_id fmt x] affiche l'identifiant [x] en utilisant le formateur [fmt],
   cf. le module {!module:Stdlib.Format}. *)
let print_id fmt x = Format.fprintf fmt "%s" x;;

(** [print_binary_op fmt op] affiche l'opérateur binaire [op] en utilisant le
   formateur [fmt]. *)
let print_binary_op fmt op =
  let s =
    match op with
    | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"
    | And -> "/\\" | Or -> "\\/"
    | Le -> "<="
  in
  Format.fprintf fmt "%s" s
;;

(** [print_unary_op fmt op] affiche l'opérateur unaire [op] en utilisant le
   formateur [fmt]. *)
let print_unary_op fmt op =
  let s =
    match op with
    | Not -> "not"
  in
  Format.fprintf fmt "%s" s
;;

let rec print_type fmt ty =
  match ty with
  | TInt ->
     Format.fprintf fmt "int"
  | TBool ->
     Format.fprintf fmt "bool"
  | TPair (ty1, ty2) ->
     Format.fprintf fmt "(@[%a *@ %a@])"
       print_type ty1
       print_type ty2
  | TFun (ty1, ty2) ->
     Format.fprintf fmt "(@[%a ->@ %a@])"
       print_type ty1
       print_type ty2
;;

(** [print_term fmt m] affiche le terme [m] en utilisant le formateur [fmt]. *)
let rec print_term fmt m =
  match m with
  | Id x ->
     print_id fmt x
  | LInt n ->
     Format.fprintf fmt "%d" n
  | LBool b ->
     Format.fprintf fmt "%b" b
  | Bop (op, m, n) ->
     Format.fprintf fmt "(@[%a %a@ %a@])"
       print_binary_op op
       print_term m
       print_term n
  | Uop (op, m) ->
     Format.fprintf fmt "(@[%a@ %a@])"
       print_unary_op op
       print_term m
  | Let (x, m, n) ->
     Format.fprintf fmt "@[let@ %a =@ %a in@ %a@]"
       print_id x
       print_term m
       print_term n
  | Pair (m, n) ->
     Format.fprintf fmt "@[(%a,@ %a)@]"
       print_term m
       print_term n
  | Fst m ->
     Format.fprintf fmt "@[(fst@ %a)@]"
       print_term m
  | Snd m ->
     Format.fprintf fmt "@[(snd@ %a)@]"
       print_term m
  | If (m, n, p) ->
     Format.fprintf fmt "@[(if %a@ then %a else@ %a)@]"
       print_term m
       print_term n
       print_term p
  | Fun (x, ty, m) ->
     Format.fprintf fmt "(@[fun (@[%a :@ %a@]).@ %a@])"
       print_id x
       print_type ty
       print_term m
  | App (m, n) ->
     Format.fprintf fmt "(@[%a@ %a@])"
       print_term m
       print_term n
;;

(** {2 Fonctions utilitaires sur les identifiants} *)

(** Enrobe les identifiants pour les rendre compatibles avec {!module:Map.S}. *)
module Id = struct type t = identifier let compare = Stdlib.compare end;;

(** Module fournissant une implementation des ensembles finis d'identifiants. *)
module S = Set.Make(Id);;

(** Module fournissant une implementation des dictionnaires d'identifiants. *)
module M = Map.Make(Id);;

(** [print_id_set fmt s] affiche l'ensemble fini d'identifiants [s] en utilisant
   le formateur [fmt]. *)
let print_id_set fmt s =
  let r = ref (S.cardinal s) in
  let print_id x =
    decr r;
    Format.fprintf fmt "%s%s@ "
      x
      (if !r > 0 then "," else "")
  in
  Format.fprintf fmt "{@[ ";
  S.iter print_id s;
  Format.fprintf fmt "@]}"
;;

(** [print_id_set fmt s] affiche l'ensemble fini d'identifiants [s] en utilisant
   le formateur [fmt]. *)
let print_id_map print_val fmt m =
  let r = ref (M.cardinal m) in
  let print_key_value_pair x v =
    decr r;
    Format.fprintf fmt "%s: %a%s@ "
      x
      print_val v
      (if !r > 0 then "," else "")
  in
  Format.fprintf fmt "{@[ ";
  M.iter print_key_value_pair m;
  Format.fprintf fmt "@]}"
;;

(** {2 Typage} *)

(** Cette section définit un typeur simple pour Marthe++. *)

exception Ill_typed of term;;

let rec type_of ctx m =
  let ill_typed () = raise (Ill_typed m) in
  match m with
  | Id x ->
     (try M.find x ctx with Not_found -> ill_typed ())

  | LInt _ ->
     TInt

  | LBool _ ->
     TBool

  | Bop (op, m, n) ->
     let ty1 = type_of ctx m in
     let ty2 = type_of ctx n in
     begin match op, ty1, ty2 with
     | (Add | Sub | Mul | Div), TInt, TInt -> TInt
     | (And | Or), TBool, TBool -> TBool
     | Le, TInt, TInt -> TBool
     | _ -> ill_typed ()
     end

  | Uop (op, m) ->
     let ty = type_of ctx m in
     begin match op, ty with
     | Not, TBool -> TBool
     | _ -> ill_typed ()
     end

  | Let (x, m, n) ->
     let ty = type_of ctx m in
     type_of (M.add x ty ctx) n

  | Pair (m, n) ->
     let ty1 = type_of ctx m in
     let ty2 = type_of ctx n in
     TPair (ty1, ty2)

  | Fst m ->
     let ty = type_of ctx m in
     begin match ty with
     | TPair (ty1, _) -> ty1
     | _ -> ill_typed ()
     end

  | Snd m ->
     let ty = type_of ctx m in
     begin match ty with
     | TPair (_, ty2) -> ty2
     | _ -> ill_typed ()
     end

  | If (m, n, p) ->
     let ty1 = type_of ctx m in
     let ty2 = type_of ctx n in
     let ty3 = type_of ctx p in
     if ty1 <> TBool || ty2 <> ty3 then ill_typed ();
     ty2

  | Fun (x, ty, m) ->
     let ty' = type_of (M.add x ty ctx) m in
     TFun (ty, ty')

  | App (m, n) ->
     let ty1 = type_of ctx m in
     let ty2 = type_of ctx n in
     begin match ty1 with
     | TFun (ty1', ty1'') ->
        if ty1' <> ty2 then ill_typed ();
        ty1''
     | _ -> ill_typed ()
     end

(** {2 Gestion des variables libres, renommage, alpha-équivalence et
   substitution} *)

(** [fv m] retourne l'ensemble des variables libres du terme [m]. *)
let rec fv m =
  match m with
  | Id x ->
     S.singleton x
  | LInt _ | LBool _ ->
     S.empty
  | Bop (_, m, n) | Pair (m, n) | App (m, n) ->
     S.union (fv m) (fv n)
  | Uop (_, m) | Fst m | Snd m ->
     fv m
  | Let (x, m, n) ->
     S.(union (fv m) (diff (fv n) (singleton x)))
  | If (m, n, p) ->
     S.(union (union (fv m) (fv n)) (fv p))
  | Fun (x, _, m) ->
     S.(diff (fv m) (singleton x))
;;

(** Mathématiquement, un renommage est une fonction partielle finie des
   identifiants dans les identifiants. En OCaml, on représente une telle
   fonction partielle finie par un dictionnaire. *)
type renaming = identifier M.t;;

(** [print_renaming fmt r] affiche le renommage [r] en utilisant le formateur
   [fmt]. *)
let print_renaming = print_id_map print_id;;

(** [naive_subst n m x] substitue [m] à toutes les occurences de [x] dans
   [n]. {b Attention} : cette substitution n'évite pas la capture, et on suppose
   donc que [m] est un terme clos. *)
let rec naive_subst n m x =
  assert (S.is_empty (fv m));
  match n with
  | Id y ->
     if x = y then m else n
  | LInt _ | LBool _ ->
     n
  | Bop (op, n1, n2) ->
     Bop (op, naive_subst n1 m x, naive_subst n2 m x)
  | Uop (op, n) ->
     Uop (op, naive_subst n m x)
  | Pair (n1, n2) ->
     Pair (naive_subst n1 m x, naive_subst n2 m x)
  | Fst n ->
     Fst (naive_subst n m x)
  | Snd n ->
     Snd (naive_subst n m x)
  | Let (y, n1, n2) ->
     let n1 = naive_subst n1 m x in
     Let (y, n1, if x = y then n2 else naive_subst n2 m x)
  | If (n1, n2, n3) ->
     If (naive_subst n1 m x, naive_subst n2 m x, naive_subst n3 m x)
  | Fun (y, ty, n) ->
     Fun (y, ty, if x = y then n else naive_subst n m x)
  | App (n1, n2) ->
     App (naive_subst n1 m x, naive_subst n2 m x)
;;
