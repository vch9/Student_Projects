open Graphics

open Dnf_to_cnf
open Types
open Affichage

(* réponse a voulez vous rejouer *)
let rec seek_answer pos_oui pos_non width height =
  let s = wait_next_event [Button_down]
  in
  if s.button then
    match ((s.mouse_x>(fst pos_oui) && s.mouse_x<((fst pos_oui)+width) && s.mouse_y>(snd pos_oui) && s.mouse_y<((snd pos_oui)+height)), 
    (s.mouse_x>(fst pos_non) && s.mouse_x<((fst pos_non)+width) && s.mouse_y>(snd pos_non) && s.mouse_y<((snd pos_non)+height))) with
    | (true, false) -> true (* rejouer *)
    | (false, true) -> false (* quitter *)
    | (false, false) | (true, true) -> seek_answer pos_oui pos_non width height
  else false
;;

let ask_retry limite =
  set_color white;
  fill_rect 0 0 limite 50;
  set_color black;
  
  draw_rect 0 35 limite 15;
  draw_rect 0 0 (limite/2) 35;
  draw_rect (limite/2) 0 (limite/2) 35;

  moveto ((limite/2)-80) 35;
  draw_string "BRAVO, voulez vous rejouer ?";
  moveto ((limite/4)-10) 15;
  draw_string "OUI";
  moveto ((limite/2+limite/4)-10) 15;
  draw_string "NON";

  seek_answer (1,0) ((limite/2)+1,0) (limite/2) 35
;;


let create_footer limite =
  set_color white;
  fill_rect 0 0 limite 49;
  set_color black;
  draw_rect 0 0 (limite/2) 49;
  moveto ((limite/4)-40) 25;
  draw_string "SOLUTION";
  draw_rect (limite/2) 0 (limite/2) 49;
  moveto ((limite/2+limite/4)) 25;
  draw_string "AIDE"
;;



(* propose l'aide de la résolution de la cnf s'il y en a une *)
let aide limite lignes rectangles cnf =
  set_color white;
  fill_rect (limite/2) 0 (limite/2) 49;
  set_color black;
  draw_rect (limite/2) 0 (limite/2) 49;

  match resultat rectangles cnf with
  | None -> moveto ((limite/2+limite/4)-90) 25; draw_string "Pas de résultat."; Unix.sleep 2; false
  | Some res -> 
    moveto ((limite/2+limite/4)-90) 35;
    draw_string "Afficher la solution?";
    moveto ((limite/2+limite/4)-30) 15;
    draw_string "Oui";
    moveto ((limite/2+limite/4)+15) 15;
    draw_string "Non";
    let s = wait_next_event [Button_down]
    in
      if s.button then
        match s.mouse_x<(limite/2+limite/4) with (* a gauche du Oui/Non donc oui *)
        | true -> afficher lignes (create_from_res res); true
        | false -> false
      else false
;;