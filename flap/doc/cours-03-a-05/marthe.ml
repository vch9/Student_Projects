(** {1 Cours 03 : Marthe} *)

(** {2 Syntaxe du langage jouet Marthe} *)

(** Type des identifiants. *)
type identifier = string
;;

(** Type des termes (expressions) du langage Marthe. *)
type term =
  | Id of identifier            (** variables *)
  | LInt of int                 (** constantes litérales entières *)
  | Add of term * term          (** addition *)
  | Mul of term * term          (** produit *)
  | Sum of identifier * term * term * term (** somme formelle *)

(** Les différentes fonctions d'affichage utilisent le module
   {!module:Stdlib.Format}. On peut ordonner au toplevel d'utiliser la fonction
   d'affichage [f] via la directive [#install_printer f]. *)

(** [print_id fmt x] affiche l'identifiant [x] en utilisant le formateur [fmt],
   cf. le module {!module:Stdlib.Format}. *)
let print_id fmt x = Format.fprintf fmt "%s" x;;

(** [print_term fmt m] affiche le terme [m] en utilisant le formateur [fmt]. *)
let rec print_term fmt m =
  match m with
  | Id x ->
     print_id fmt x
  | LInt n ->
     Format.fprintf fmt "%d" n
  | Add (m, n) ->
     Format.fprintf fmt "(@[%a +@ %a@])"
       print_term m
       print_term n
  | Mul (m, n) ->
     Format.fprintf fmt "(@[%a *@ %a@])"
       print_term m
       print_term n
  | Sum (x, m, n, p) ->
     Format.fprintf fmt "sum (@[%a,@ %a,@ %a,@ %a@])"
       print_id x
       print_term m
       print_term n
       print_term p
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
  | LInt n ->
     S.empty
  | Id x ->
     S.singleton x
  | Add (m, n) | Mul (m, n) ->
     S.union (fv m) (fv n)
  | Sum (x, m, n, p) ->
     S.union
       (S.union (fv m) (fv n))
       (S.diff (fv p) (S.singleton x))
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

(** [rename m y x] remplace toutes les occurences libres de [x] dans [m] par
   [y]. *)
let rec rename m y x =
  match m with
  | Id z ->
     Id (if z = x then y else z)
  | LInt _ ->
     m
  | Add (m, n) ->
     Add (rename m y x, rename n y x)
  | Mul (m, n) ->
     Mul (rename m y x, rename n y x)
  | Sum (z, m, n, p) ->
     if z = x
     then Sum (z, rename m y x, rename n y x, p)
     else
       let k = fresh (S.add y (fv p)) in
       Sum (k, rename m y x, rename n y x, rename (rename p k z) y x)
;;

(** [alpha_eq m n] vaut [true] ssi [m] et [n] sont égaux à un renommage de leurs
   variables liées près. *)
let rec alpha_eq m n =
  match m, n with
  | Id x, Id y ->
     x = y
  | LInt i, LInt j ->
     i = j
  | Add (m, n), Add (m', n') | Mul (m, n), Mul (m', n') ->
     alpha_eq m m' && alpha_eq n n'
  | Sum (x, m, n, p), Sum (y, m', n', p') ->
     alpha_eq m m' && alpha_eq n n'
     &&
       let z = fresh (S.union (fv p) (fv p')) in
       alpha_eq (rename p z x) (rename p' z y)
  | _ ->
     false
;;

(** [subst n m x] remplace toutes les occurences libres de [x] dans [n] par
    [m]. *)
let rec subst n m x =
  match n with
  | Id y ->
     if y = x then m else Id y
  | LInt n ->
     LInt n
  | Add (n, p) ->
     Add (subst n m x, subst p m x)
  | Mul (n, p) ->
     Mul (subst n m x, subst p m x)
  | Sum (y, n, p, o) ->
     if y = x
     then Sum (y, subst n m x, subst p m x, o)
     else
       let k = fresh (S.union (fv o) (fv m)) in
       Sum (k, subst n m x, subst p m x, subst (rename o k y) m x)
;;

(** {2 Évaluation} *)

(** On représente les environnements par des dictionnaires associant des entiers
   aux valeurs. *)
type env = int M.t

(** [eval m env] renvoie l'entier [n] résultant de l'évaluation de [m] dans
   l'environnement [m]. Si [fv m] n'est pas inclut dans l'ensemble des clés de
   [env], la fonction lève l'exception {!exception:Not_found}. *)
let rec eval m env =
  match m with
  | Id x ->
     M.find x env
  | LInt i ->
     i
  | Add (m, n) ->
     eval m env + eval n env
  | Mul (m, n) ->
     eval m env * eval n env
  | Sum (x, m, n, p) ->
     let lo = eval m env in
     let hi = eval n env in
     let rec eval_on_range lo =
       if lo <= hi then eval p (M.add x lo env) + eval_on_range (lo + 1) else 0
     in
     eval_on_range lo
