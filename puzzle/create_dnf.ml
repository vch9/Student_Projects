open Types
open Graphics
open Creation

let add_to_all x l =
  List.map (fun a -> x::a) l
;;

(* crée les permutations avec au maximum dedans, i toAdd dans la liste *)
(* ce qui correspond a, i rectangles rouge ou bleu adjacents a la ligne donnée *)
let rec affect_rect (l: rect list) (i:int) (toAdd:bool) : ((bool * rect) list list)=
  match l with
  | [] -> [[]]
  | t::q ->
      let left =
        if (i>0) then add_to_all (toAdd, t) (affect_rect q (i-1) toAdd)
        else []

      in left@add_to_all (not toAdd, t) (affect_rect q i toAdd)

;;
(* compte le nombre de true ou false dans la liste *)
let count_bool liste =
  let rec aux l t f =
    match l with
    | [] -> (t,f)
    | a::q-> if(fst a) then aux q (t+1) f else aux q t (f+1)
  in aux liste 0 0
;;
(* prend les permutations en enlevant celles ou le nombre de false=true, pour que ca ne respecte pas les lignes magenta *)
let rec filtrer (liste: (bool * rect) list list) =
  match liste with
  | [] -> []
  | t::q ->
  let x = count_bool t
  in 
  if ((fst x)<>(snd x)) then t::filtrer q else filtrer q
;;
(* 
L'idée est de créer la DNF qui ne satisfait pas le problème, par exemple si la ligne est magenta, elle donnera tous les cas
où le nombre de bleus != nombre de rouges
*)
let permutation couleur (rectangles_adj: rect list) : ((bool * rect) list list)=
  let taille = List.length rectangles_adj
  in
  if(couleur=blue) then (affect_rect rectangles_adj (taille/2) true) (* ok *)
  else if (couleur=red) then (affect_rect rectangles_adj (taille/2) false) (* ok *)
  else if (couleur=black) then []
  else filtrer ((affect_rect rectangles_adj taille false)) (* moins bonne complexité *)
;;

(* va créer les clauses de la DNF pour toutes les lignes *)
let rec create_dnf (lignes: line list) rectangles : ((bool * rect) list list list) = 
  let rec aux l res =
    match l with 
      [] -> res
    | t::q ->  
    let ligne = if ((fst t.deb) = (fst t.fin)) then (fst t.deb) else (snd t.deb) in
    aux q ((permutation t.couleur (parcours ligne rectangles (ligne=(fst t.deb))))::res)
  in
  aux lignes []
;;