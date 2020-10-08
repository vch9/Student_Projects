open Types
open Graphics
open Creation

let add_to_all x l =
  List.map (fun a -> x::a) l
;;
let rec affect_rect (l: rect list) (i:int) (toAdd:bool) (elseAdd:bool) : ((bool * rect) list list)=
  match l with
  | [] -> [[]]
  | t::q ->
      let left =
        if (i>0) then add_to_all (elseAdd, t) (affect_rect q (i-1) toAdd elseAdd)
        else []

      in left@add_to_all (toAdd, t) (affect_rect q i toAdd elseAdd)

;;
let count_bool liste =
  let rec aux l t f =
    match l with
    | [] -> (t,f)
    | a::q-> if(fst a) then aux q (t+1) f else aux q t (f+1)
  in aux liste 0 0
;;
let rec filtrer (liste: (bool * rect) list list) =
  match liste with
  | [] -> []
  | t::q ->
  let x = count_bool t
  in 
  if ((fst x)<>(snd x)) then t::filtrer q else filtrer q
;;

let permutation couleur (rectangles_adj: rect list) : ((bool * rect) list list)=
  let taille = List.length rectangles_adj
  in
  if(couleur=blue) then (affect_rect rectangles_adj (taille/2) true false) (* ok *)
  else if (couleur=red) then (affect_rect rectangles_adj (taille/2) false true) (* ok *)
  else if (couleur=black) then []
  else filtrer ((affect_rect rectangles_adj taille false true)) (* moins bonne complexité *)
;;
(* 175 0 0 = rouge *)
let rec create_cnf (lignes: line list) rectangles =
 (* ((bool * rect) list list list) =  *)
  let rec aux l res =
    match l with 
      [] -> res
    | t::q ->  
    let ligne = if ((fst t.deb) = (fst t.fin)) then (fst t.deb) else (snd t.deb) in
    aux q ((permutation t.couleur (parcours ligne rectangles (ligne=(fst t.deb))))@res)
  in
  aux lignes []
;;
let rec add_all_rec_colored (rectangles: rect list) : (bool * rect) list list =
  match rectangles with
  | [] -> []
  | t::q -> [(true, t); (false, t)]::add_all_rec_colored q
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

let rec create_from_res (res: (bool * rect) list) =
  match res with
  | [] -> []
  | t::q ->
  let c = if (fst t) then (rgb 0 0 120) else (rgb 175 0 0)
  in
  {couleur=(Some c); xd=((snd t).xd); xf=((snd t).xf); yd=((snd t).yd); yf=((snd t).yf)}::create_from_res q
;;

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

let resultat (lignes: line list) (actual_res: rect list) =
  let rects_vide = vider actual_res in
  Sat.solve (config_actuel_to_cnf actual_res ((add_all_rec_colored rects_vide)@(create_cnf lignes rects_vide)))
 ;;
 
