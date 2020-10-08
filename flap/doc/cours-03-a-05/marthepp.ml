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
  | Fun of identifier * term        (** fonction anonyme *)
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

(** [print_unary_op fmt op] affiche l'opérateur unaire [op] en utilisant le
   formateur [fmt]. *)
let print_unary_op fmt op =
  let s =
    match op with
    | Not -> "not"
  in
  Format.fprintf fmt "%s" s

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
  | Fun (x, m) ->
     Format.fprintf fmt "(fun %a.@ %a)"
       print_id x
       print_term m
  | App (m, n) ->
     Format.fprintf fmt "(%a@ %a)"
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
  | Fun (x, m) ->
     S.(diff (fv m) (singleton x))
;;

(** Mathématiquement, un renommage est une fonction partielle finie des
   identifiants dans les identifiants. En OCaml, on représente une telle
   fonction partielle finie par un dictionnaire. *)
type renaming = identifier M.t;;

(** [print_renaming fmt r] affiche le renommage [r] en utilisant le formateur
   [fmt]. *)
let print_renaming = print_id_map print_id;;

(** [fresh s] retourne un identifiant n'appartenant pas à l'ensemble [s]. **)
let fresh s =
  (* Il y a une solution beaucoup plus efficace utilisant [S.min_elt]. On peut
     encore utiliser un compteur global. *)
  let rec loop prefix i =
    let x = prefix ^ string_of_int i in
    if S.mem x s then loop prefix (i + 1) else x
  in
  loop "x" 0
;;

(** À faire : implémenter la substitution ! *)

(** {2 Évaluation} *)

(** Cette section définit un évaluateur à grands pas pour Marthe++. *)

type value =
  | VInt of int                             (** entier *)
  | VBool of bool                           (** booléen *)
  | VPair of value * value                  (** paire *)
  | VClo of identifier * term * environment (** fermeture *)

and environment = value M.t

(** [print_value fmt v] affiche la valeur [v] en utilisant le formateur
   [fmt]. *)
let rec print_value fmt v =
  match v with
  | VInt n ->
     Format.fprintf fmt "%d" n
  | VBool b ->
     Format.fprintf fmt "%b" b
  | VPair (v, w) ->
     Format.fprintf fmt "@[(%a,@ %a)@]"
       print_value v
       print_value w
  | VClo (x, m, env) ->
     Format.fprintf fmt "@[clo(%a,@ %a,@ %a)@]"
       print_id x
       print_term m
       print_environment env

(** [print_environment fmt env] affiche l'environnement [env] en utilisant le
   formateur [fmt]. *)
and print_environment fmt env =
  print_id_map print_value fmt env
;;

exception Ill_typed

let rec eval env m =
  match m with
  | Id x ->
     M.find x env

  | LInt n ->
     VInt n

  | LBool b ->
     VBool b

  | Bop (op, m, n) ->
     let v = eval env m in
     let w = eval env n in
     begin match op, v, w with
     | Add, VInt m, VInt n -> VInt (m + n)
     | Sub, VInt m, VInt n -> VInt (m - n)
     | Mul, VInt m, VInt n -> VInt (m * n)
     | Div, VInt m, VInt n -> VInt (m / n)
     | And, VBool b1, VBool b2 -> VBool (b1 && b2)
     | Or, VBool b1, VBool b2 -> VBool (b1 || b2)
     | Le, VInt m, VInt n -> VBool (m <= n)
     | _ -> raise Ill_typed
     end

  | Uop (op, m) ->
     let v = eval env m in
     begin match op, v with
     | Not, VBool b -> VBool (not b)
     | _ -> raise Ill_typed
     end

  | Let (x, m, n) ->
     let v = eval env m in
     eval (M.add x v env) n

  | Pair (m, n) ->
     let v = eval env m in
     let w = eval env n in
     VPair (v, w)

  | Fst m ->
     begin match eval env m with
     | VPair (v, _) -> v
     | _ -> raise Ill_typed
     end

  | Snd m ->
     begin match eval env m with
     | VPair (_, v) -> v
     | _ -> raise Ill_typed
     end

  | If (m, n, p) ->
     begin match eval env m with
     | VBool true -> eval env n
     | VBool false -> eval env p
     | _ -> raise Ill_typed
     end

  | Fun (x, m) ->
     VClo (x, m, env)

  | App (m, n) ->
     let v = eval env m in
     let v_a = eval env n in
     begin match v with
     | VClo (x, m_f, env_f) ->
        eval (M.add x v_a env_f) m_f
     | _ ->
        raise Ill_typed
     end
;;


(* À commenter/décommenter selon si l'on est dans le top-level ou pas. *)
(* #install_printer print_term;;
 * #install_printer print_value;;
 * #install_printer print_environment;; *)
