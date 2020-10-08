open Jeu

let rec main () =
  print_endline "Quelle hauteur voulez vous ?";
  try 
    let hauteur = read_int () in
    print_endline "Quelle largeur voulez vous ?";
    let largeur = read_int () in
    print_endline "Combien voulez vous de noeuds ?";
    let nb_noeuds = read_int () in
    print_endline "Quelle profondeur pour l'arbre ?";
    let prof = read_int () in
    boucle hauteur largeur nb_noeuds prof
  with Failure s -> print_endline "Tapez un entier !"; main ()
;;

main ();; 