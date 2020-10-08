open Types
open Sat_solver
open Graphics
open Creation
open Create_dnf

(* ajoute la condition, tous les rectangles sont rouge ou bleu *)
let rec add_all_rec_colored (rectangles: rect list) : (bool * rect) list list =
  match rectangles with
  | [] -> []
  | t::q -> [(true, t); (false, t)]::add_all_rec_colored q
;;
(*
  convert_to_cnf, convert_one, negation sont des fonctions qui permettent d'appliquer les lois De Morgan,
  afin d'obtenir la négation de la DNF qui nous donne une CNF a donner au Sat.
  Comme la DNF était la négation de la solution, sa négation va donner une CNF qui résoud le problème.
*)
let rec negation (liste: (bool * rect) list) : (bool * rect) list =
  match liste with
  | [] -> []
  | t::q -> if(fst t) then (false, (snd t))::negation q else (true, (snd t))::negation q
;;
let rec convert_one (liste: (bool * rect) list list) : (bool * rect) list list=
  match liste with
  | [] -> []
  | t::q -> (negation t)::(convert_one q) 
;;
let rec convert_to_cnf (dnf: (bool * rect) list list list) : (bool * rect) list list =
  match dnf with
  | [] -> []
  | t::q -> (convert_one t) @ (convert_to_cnf q)
;;
module Variables = struct
  type t = rect 
  let compare x y = 
    if (x.xd=y.xd && x.xf=y.xf && x.yd=y.yd && x.yf=y.yf) then 0
    else 
      if ( ((x.xf-x.xd)*(x.yf-x.yd)) = ((y.xf-y.xd)*(y.yf-y.yd)) ) then
        if (x.xd=y.xd) then
          if (x.yd>y.yd) then 1 else -1
        else 
          if (x.xd>y.xd) then 1 else -1
      else 
        if ( ((x.xf-x.xd)*(x.yf-x.yd)) > ((y.xf-y.xd)*(y.yf-y.yd))) then 1
        else -1
  end
;;
module Sat = Sat_solver.Make(Variables);;

(* convertie le résultat donné par le sat en une liste de rectangles coloriables *)
let rec create_from_res (res: (bool * rect) list) =
  match res with
  | [] -> []
  | t::q ->
  let c = if (fst t) then (rgb 0 0 120) else (rgb 175 0 0)
  in
  {couleur=(Some c); xd=((snd t).xd); xf=((snd t).xf); yd=((snd t).yd); yf=((snd t).yf)}::create_from_res q
;;

(* rajoute les rectangles actuels a la cnf si des rectangles ont déjà été coloriés *)
let rec config_actuel_to_cnf (rects: rect list) (cnf: (bool * rect) list list) =
  match rects with
  | [] -> cnf
  | t::q ->
    match t.couleur with
    | None -> config_actuel_to_cnf q cnf
    | Some c ->
    if (c = (rgb 0 0 120)) then config_actuel_to_cnf q ([(true,{couleur=None; xd=t.xd; xf=t.xf; yd=t.yd; yf=t.yf})]::cnf)
    else config_actuel_to_cnf q ([(false,{couleur=None; xd=t.xd; xf=t.xf; yd=t.yd; yf=t.yf})]::cnf)
;;
let cnf rects lignes = 
  let rects_vide = vider rects in
  (add_all_rec_colored rects_vide)@(convert_to_cnf (create_dnf lignes rects_vide))
;;
let resultat actual_res cnf =
  Sat.solve (config_actuel_to_cnf actual_res cnf)
 ;;
 