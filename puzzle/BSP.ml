open Graphics;;
open Printf;;
type label = { coord : int; colored : bool;}
type bsp = R of color option | L of label * bsp * bsp
type rect = { couleur: color option; xd:int; xf:int; yd:int; yf:int;}
type line = { colored:bool; deb:int * int ; fin:int * int; couleur: color }
let limite = 1000;;
(* let arbre = L ({coord = 272; colored = true},L({coord = 380; colored = true},L({coord = 100; colored = true},R (Some (rgb 175 0 0)),R (Some (rgb 0 0 120))),L({coord = 62; colored = true},R (Some (rgb 0 0 120)),R (Some (rgb 175 0 0)))),L({coord = 172; colored = true},L({coord = 375; colored = true},R (Some (rgb 175 0 0)),R (Some (rgb 0 0 120))),L({coord = 300; colored = true},R (Some (rgb 0 0 120)),L({coord = 250; colored = true},R (Some (rgb 175 0 0)),R (Some (rgb 0 0 120)))))) *)


let calculer_couleur (lignes: color option list) =
  let rec aux lignes nb_rouge nb_bleu =
    match lignes with
      [] ->
            if (nb_rouge=nb_bleu) then (rgb 255 100 255)
            else
              if (nb_rouge > nb_bleu) then red
              else blue
    | t::q ->
      match t with
        None -> aux q nb_rouge nb_bleu
      | Some c ->
        if(c=(rgb 0 0 120)) then aux q nb_rouge (nb_bleu+1)
        else aux q (nb_rouge+1) nb_bleu

  in aux lignes 0 0
;;
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
let rec parcours (ligne:int) (rectangles:rect list) (abscisse:bool) =
  match rectangles with
    [] -> []
  | t::q ->
    if (abscisse) then
      if ((t.xd-1)=ligne || (t.xf+1)=ligne) then t.couleur::parcours ligne q abscisse
      else parcours ligne q abscisse
    else
      if ((t.yd-1)=ligne || (t.yf+1)=ligne) then t.couleur::parcours ligne q abscisse
      else parcours ligne q abscisse
  (* si c'est une ligne abscisse x-1 et x+1 *) (* si c'est une ligne ordo y-1 et y+1*)
;;
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
      let coul = if(l.colored=true) then calculer_couleur (parcours l.coord rectangles true) else black
      in
        [{colored=l.colored; deb=(xd, l.coord); fin=(xf, l.coord); couleur = coul }]@(recLineAbsi g xd xf yd (l.coord-1) liste)@(recLineAbsi d xf xf (l.coord+1) yf liste)
in recLineAbsi arbre xd xf yd yf []
;;

let draw c rect =
  set_color c; fill_rect (rect.xd) (rect.yd-1) (rect.xf-rect.xd+1) (rect.yf-rect.yd+1);
;;
let rec draw_rectangles (rectangles: rect list) =
  match rectangles with
    [] -> ()
  | t::q ->
  let c =
    match t.couleur with
      Some co -> co
    | None -> white
  in
  set_color c; draw c t; draw_rectangles q
;;
let rec draw_lignes lignes =
  match lignes with
    [] -> ()
  | t::q ->
      set_color t.couleur; moveto (fst t.deb) (snd t.deb); lineto (fst t.fin) (snd t.fin);
      draw_lignes q
;;

let next_color couleur =
  match couleur with
    None -> Some (rgb 175 0 0)
  | Some (c) -> if (c=(rgb 175 0 0)) then Some (rgb 0 0 120) else None
;;
let check couleur liste_couleurs =
  couleur = (calculer_couleur liste_couleurs)
;;
let rec check_current lignes rectangles =
  (* vérifier pour chaque ligne si les rectangles adjacents respectent la couleur *)
  match lignes with
    [] -> set_color black; fill_rect 0 0 500 500
  | t::q ->
    let ligne = if ((fst t.deb)=(fst t.fin)) then (fst t.deb) else (snd t.deb)
    in
      if (check t.couleur (parcours ligne rectangles (ligne=(fst t.deb)))) then check_current q rectangles else ()
;;
let rec fini (rectangles: rect list) =
  match rectangles with
    [] -> true
  | t::q -> if(t.couleur=None) then false else fini q
;;
let act_mouse x y lignes rectangles =
  let rec aux liste l =
    match liste with
      [] -> l
    | t::q -> if(x>t.xd && x<t.xf && y>t.yd && y<t.yf) then {couleur= (next_color t.couleur); xd=t.xd; xf=t.xf; yd=t.yd; yf=t.yf}::aux q l else t::aux q l
  in
  rectangles := (aux !rectangles []); draw_rectangles !rectangles;
  if(fini !rectangles) then check_current lignes !rectangles else ()

let act_key key =
  match key with
    'Q' -> close_graph ()
  | _ -> ()
;;

(* let rec ajoutNoeud bsp label currentEven even =
	match bsp with
	| R(a) -> L(label, R(a), R(a))
	| L(l,g,d) ->
	if currentEven = even then
		if label.coord = l.coord then bsp
		else if label.coord < l.coord then ajoutNoeud g label (not currentEven) even
		else ajoutNoeud d label (not currentEven) even
	else let rand = Random.int 1 in
	 ajoutNoeud (if rand = 0 then g else d) label (not currentEven) even
;;
let createBsp maxHeight maxWidth nodeNb =
	let firstBsp = L ({coord = (Random.int maxWidth); colored = false;}, R(None),R(None)) in
	let rec createBspAux bsp max nb even =
		let newLabel = {coord = (Random.int max); colored = false;} in
			ajoutNoeud bsp newLabel (nb-1) even true in
		if nb < 0 then bsp
	else createBspAux bsp (if even then maxWidth else maxHeight) nb-1 (not even)
;; *)
let createBsp maxWidth maxHeight nodeNb =
  L({coord=(Random.int maxWidth); colored=false}, R None, R None)
;;
let arbre = createBsp 500 500 1;;
let () =
  let rect_from_bsp = ref (rectangles_from_bsp arbre 0 limite 0 limite)
  in
    let lignes = lines_from_bsp arbre 0 limite 0 limite !rect_from_bsp
    in
      open_graph " 500x500";
      (* draw_rectangles rect_from_bsp; *)
      draw_lignes lignes;
      rect_from_bsp := List.map (fun x -> {couleur=None; xd=x.xd; xf=x.xf; yd=x.yd; yf=x.yf}) !rect_from_bsp;
      while true do
          let s = wait_next_event [Button_down; Key_pressed]
          in
            if s.button then
              act_mouse s.mouse_x s.mouse_y lignes rect_from_bsp
            else if s.keypressed then act_key s.key
      done

        (* ignore (input_char stdin) *)
;;

(* rouge des rectangles: rgb 175 0 0
   bleu des rectangles:  rgb 0 0 120
*)
