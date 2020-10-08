open Graphics
open Types
open Affichage
open Creation
open Buttons
open Dnf_to_cnf

(* vérifie si la couleur de la ligne est égal a celle qu'on calcul avec les réctangles adjacents *)
let check couleur liste_couleurs =
  couleur = (calculer_couleur liste_couleurs)
;;
(* vérifie si la composition actuelle est bonne *)
let rec check_current lignes rectangles =
  (* vérifier pour chaque ligne si les rectangles adjacents respectent la couleur *)
  match lignes with
    [] -> true
  | t::q ->
    let ligne = if ((fst t.deb)=(fst t.fin)) then (fst t.deb) else (snd t.deb)
    in
      if (t.colored = false) then check_current q rectangles
      else
        if (check t.couleur (parcours ligne rectangles (ligne=(fst t.deb)))) then check_current q rectangles
        else false
;;

(* tous les rectangles sont coloriés *)
let rec fini (rectangles: rect list) =
  match rectangles with
    [] -> true
  | t::q -> if(t.couleur=None) then false else fini q
;;

(* cherche le rect et change sa couleur *)
let change_color x y lignes rectangles =
  let rec aux liste l =
    match liste with
      [] -> l
    | t::q -> if(x>t.xd && x<t.xf && y>t.yd && y<t.yf) then {couleur= (next_color t.couleur); xd=t.xd; xf=t.xf; yd=t.yd; yf=t.yf}::aux q l else t::aux q l
  in
  rectangles := (aux !rectangles []);

;;


(* gère les actions de l'utilisateur *)
let play largeur solution lignes cnf =
  let rect_from_bsp = ref (vider solution) in
  afficher lignes !rect_from_bsp;
  create_footer largeur;
  try
    while true do 
      let s = wait_next_event [Button_down]
      in
        if s.button then
          match ((s.mouse_x<(largeur/2) && s.mouse_y<50), (s.mouse_x>(largeur/2) && s.mouse_y<50)) with
            (true, false) -> afficher lignes solution; raise Exit; (* il demande la solution *)
          | (false, true) -> 
          if (aide largeur lignes !rect_from_bsp cnf) then raise Exit (* il demande de l'aide *)
          else create_footer largeur
          | (true, true) | (false, false) ->
            change_color s.mouse_x s.mouse_y lignes rect_from_bsp; afficher lignes !rect_from_bsp;
            if(fini !rect_from_bsp) then 
              if(check_current lignes !rect_from_bsp) then 
                raise Exit; (* a gagné normalement *)
    done
  with Exit -> ()
;;

(* crée l'arbre, en extrait la coloration via les réctangles et les lignes *)
let start_game hauteur largeur nb prof =
  let window = " "^(string_of_int largeur)^"x"^(string_of_int (hauteur+50)) in
  open_graph window;
  Random.self_init();
  let arbre = createBsp (R None) nb 0 largeur 50 (hauteur+50) prof;
  in
  let solution = (colorier_random (rectangles_from_bsp arbre 0 largeur 50 (hauteur+50))) 
  in
  let lignes = lines_from_bsp arbre 0 largeur 50 (hauteur+50) solution
  in
  clear_graph ();
  play largeur solution lignes (cnf solution lignes)
;;




(* relance une partie tant que l'utilisateur le demande *)
let boucle hauteur largeur nb prof =
   try
    while true do
      start_game hauteur largeur nb prof;
      if(not (ask_retry largeur)) then raise Exit
      else resize_window largeur (hauteur+50)
    done
  with Exit -> () 
;;