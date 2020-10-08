open Types
open Graphics

let draw c rect =
  (* windows: *)
  (* set_color c; fill_rect (rect.xd) (rect.yd-1) (rect.xf-rect.xd+1) (rect.yf-rect.yd+1); *)

  (* linux *)
  set_color c; fill_rect (rect.xd) (rect.yd) (rect.xf-rect.xd) (rect.yf-rect.yd);
;;

let rec draw_rectangles (rectangles: rect list) =
  match rectangles with
    [] -> ()
  | t::q ->
          let c =
              match t.couleur with
                Some co -> co
              | None -> white
            in draw c t; draw_rectangles q
;;

let rec draw_lignes lignes =
  match lignes with
    [] -> ()
  | t::q ->
      set_color t.couleur; moveto (fst t.deb) (snd t.deb); lineto (fst t.fin) (snd t.fin);
      draw_lignes q
;;

(* parcours rectangles et lignes pour les afficher via graphics *)
let afficher lignes rectangles =
  draw_rectangles rectangles; draw_lignes lignes
;;