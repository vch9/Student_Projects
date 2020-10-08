open Types
open Graphics

(* boucle couleur pour l'utilisateur *)
let next_color couleur =
  match couleur with
    None -> Some (rgb 175 0 0)
  | Some (c) -> if (c=(rgb 175 0 0)) then Some (rgb 0 0 120) else None
;;

(* parcours les rectangles adjacents a la ligne pour calculer la couleur *)
let calculer_couleur (lignes: rect list) =
  let rec aux (lignes: rect list) nb_rouge nb_bleu =
    match lignes with
      [] ->
            if (nb_rouge=nb_bleu) then (rgb 255 100 255)
            else
              if (nb_rouge > nb_bleu) then red
              else blue
    | t::q ->
      match t.couleur with
        None -> aux q nb_rouge nb_bleu
      | Some c ->
        if(c=(rgb 0 0 120)) then aux q nb_rouge (nb_bleu+1)
        else aux q (nb_rouge+1) nb_bleu

  in
  aux lignes 0 0
;;

(* extrait la liste des rectangles du bsp *)
let rectangles_from_bsp (arbre: bsp) (xd:int) (xf:int) (yd:int) (yf:int) =
  let rec recAbsi (arbre: bsp) xd xf yd yf =
    match arbre with
      R(c) -> [{couleur=c; xd=xd; xf=xf; yd=yd; yf=yf}]
    | L(l,g,d) -> (recOrdo g xd (l.coord-1) yd yf)@(recOrdo d (l.coord+1) xf yd yf)
  and recOrdo arbre xd xf yd yf =
    match arbre with
      R(c) -> [{couleur=c; xd=xd; xf=xf; yd=yd; yf=yf}]
    | L(l,g,d) -> (recAbsi g xd xf yd (l.coord-1))@(recAbsi d xd xf (l.coord+1) yf)
in recAbsi arbre xd xf yd yf
;;

let rec colorier_random (rectangles:rect list) : (rect list) =
    match rectangles with
      [] -> []
    | t::q -> let c = if(Random.bool ()) then (rgb 175 0 0) else (rgb 0 0 120)
              in {couleur=(Some c); xd=t.xd; xf=t.xf; yd=t.yd; yf=t.yf}::colorier_random q
;;
(* donne les rectangles adjacent a une ligne (représenté par le label) *)
let rec parcours (ligne:int) (rectangles:rect list) (abscisse:bool) =
  match rectangles with
    [] -> []
  | t::q ->
    if (abscisse) then
      if ((t.xd-1)=ligne || (t.xf+1)=ligne) then t::parcours ligne q abscisse
      else parcours ligne q abscisse
    else
      if ((t.yd-1)=ligne || (t.yf+1)=ligne) then t::parcours ligne q abscisse
      else parcours ligne q abscisse
  (* si c'est une ligne abscisse x-1 et x+1 *) (* si c'est une ligne ordo y-1 et y+1*)
;;

(* extrait les lignes du bsp *)
let lines_from_bsp (arbre:bsp) (xd:int) (xf:int) (yd:int) (yf:int) (rectangles:rect list)  =
  let rec recLineAbsi (arbre:bsp) (xd:int) (xf:int) (yd:int) (yf:int) (liste:line list) =
    match arbre with
      R(c) -> liste
    | L(l,g,d) ->
        let coul = if(l.colored=true) then calculer_couleur (parcours l.coord rectangles true)  else black
        in
    [{colored=l.colored; deb=(l.coord, yd); fin=(l.coord, yf); couleur = coul }]@(recLineOrdo g xd (l.coord-1) yd yf liste)@(recLineOrdo d (l.coord+1) xf yd yf liste)
  and recLineOrdo (arbre:bsp) (xd:int) (xf:int) (yd:int) (yf:int) (liste:line list) =
    match arbre with
      R(c) -> liste
    | L(l,g,d) ->
      let coul = if(l.colored=true) then calculer_couleur (parcours l.coord rectangles false) else black
      in
  
        [{colored=l.colored; deb=(xd, l.coord); fin=(xf, l.coord); couleur = coul }]@(recLineAbsi g xd xf yd (l.coord-1) liste)@(recLineAbsi d xd xf (l.coord+1) yf liste)
in recLineAbsi arbre xd xf yd yf []
;;

let rec profondeur_min arbre = 
  match arbre with  
    R(c) -> 0
  | L (l,g,d) -> 1 + (min (profondeur_min g) (profondeur_min d))
;;
let create_label deb fin =
  if (fin-deb)<3 then R None (* pas la place de mettre un noeud *)
  else 
  (
    let label = let x = (Random.int (fin-deb))+deb in
    if x = deb || x = deb+1 then deb+2
    else if x = fin || x = fin-1 then fin-2
    else x
    in
    L({coord=label; colored=true}, R None, R None)
  )
;;
(* crée un arbre aléatoirement sans couleurs, parcours aléatoirement si le chemin respecte la profondeur pour rajouter un noeud *)
let rec createBsp (node:bsp) (nb_nodes:int) xd xf yd yf (profondeur_max:int)=
  let rec createAbsi arbre xd xf yd yf current_prof prof_max =
    match arbre with
      R(c) -> create_label xd xf
      (* let label = ((Random.int (xf-xd-1))+xd) in
      L({coord= label; colored=true}, R None, R None) *)
    | L(l,g,d) -> 
      if(Random.bool () && (current_prof+(profondeur_min g))+1 < profondeur_max) then
        L(l, (createOrdo g xd (l.coord-1) yd yf (current_prof+1) prof_max), d)
      else
        if ((current_prof+(profondeur_min d))+1 < profondeur_max) then
          L(l, g, (createOrdo d (l.coord+1) xf yd yf (current_prof+1) prof_max))
        else arbre
  and createOrdo arbre xd xf yd yf current_prof prof_max =  
    match arbre with
    R(c) -> create_label yd yf
    (* let label = ((Random.int (yf-yd-1))+yd) in
    L({coord= label; colored=true}, R None, R None) *)
  | L(l,g,d) -> 
    if(Random.bool () && (current_prof+(profondeur_min g))+1 < profondeur_max) then
      L(l, (createAbsi g xd xf yd (l.coord-1) (current_prof+1) prof_max), d)
    else
      if ((current_prof+(profondeur_min d))+1 < profondeur_max) then
        L(l, g, (createAbsi d xd xf (l.coord+1) yf (current_prof+1) prof_max))
      else arbre
in 
if (nb_nodes<=0) then node
else createBsp (createAbsi node xd xf yd yf 0 profondeur_max) (nb_nodes-1) xd xf yd yf profondeur_max
;;


let rec vider solution =
  match solution with
  | [] -> []
  | t::q -> {couleur=None; xd=t.xd; xf=t.xf; yd=t.yd; yf=t.yf}::vider q
;;