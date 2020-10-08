open Creation
open Types
open Affichage
open Dnf_to_cnf
open Graphics

let limite = 500;;
(* let arbre = createBsp (R None) 6 0 limite 0 500 4;; *)
let arbre = 
L ({coord = 545; colored = true}, 
  R (Some (rgb 0 0 120)), 
  L({coord = 300; colored=true}, R (Some (rgb 175 0 0)), R (Some (rgb 175 0 0)))
  )
;;
let rectangles = rectangles_from_bsp arbre 0 500 0 500;;
let lignes = lines_from_bsp arbre 0 500 0 500 rectangles;;

let res = (resultat lignes rectangles);;
