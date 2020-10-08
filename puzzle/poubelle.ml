let rec afficher_ligne l =
  match l with
  | [] -> ()
  | t::q -> 
    match t with 
    | (true, x) -> print_string "true,"; afficher_ligne q
    | (false, x) -> print_string "false,"; afficher_ligne q
  
let rec afficher_dnf_2 l =
  match l with
  | [] -> ()
  | t::q -> print_string "["; afficher_ligne t; print_string "]; "; afficher_dnf_2 q
;;
let rec afficher_dnf dnf =
  match dnf with
  | [] -> ()
  | t::q -> print_string "{"; afficher_dnf_2 t; print_string "}\n"; afficher_dnf q
;;

let rec create_from_res (res: (bool * rect) list) =
  match res with
  | [] -> []
  | t::q ->
  let c = if (fst t) then (rgb 0 0 120) else (rgb 175 0 0)
  in
  {couleur=(Some c); xd=((snd t).xd); xf=((snd t).xf); yd=((snd t).yd); yf=((snd t).yf)}::create_from_res q
;;

let rec afficher_clause l =
  match l with
  | [] -> ()
  | t::q ->
    match t with
    | (true, x) ->
    print_string "(true, {xd="; print_int x.xd; print_string "; xf="; print_int x.xf; print_string "; yd="; print_int x.yd; print_string "; yf="; print_int x.yf; print_string "})";afficher_clause q
    | (false, x) ->
    print_string "(false, {xd="; print_int x.xd; print_string "; xf="; print_int x.xf; print_string "; yd="; print_int x.yd; print_string "; yf="; print_int x.yf; print_string "})";afficher_clause q
;;
let rec afficher_cnf cnf =
  match cnf with
  | [] -> ()
  | t::q -> print_string "\n["; afficher_clause t; print_string "]"; afficher_cnf q
;;