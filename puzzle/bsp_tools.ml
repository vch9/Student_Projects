open Graphics;;


type label = { coord : int; colored : bool; }
type bsp = R of color option | L of label * bsp * bsp

let rec pow a = function
  | 0 -> 1
  | 1 -> a
  | n ->  
    let b = pow a (n / 2) in
    b * b * (if n mod 2 = 0 then 1 else a);;

let rec addNode bsp label currentEven even =
  match bsp with
  | R(a) -> if currentEven = even then L(label, R(a), R(a)) else bsp
  | L(l,g,d) -> 
  if currentEven = even then
  begin
    if label.coord = l.coord then bsp 
    else if label.coord < l.coord then L(l, (addNode g label currentEven (not even)) ,d)
    else L(l, g ,(addNode d label currentEven (not even)))
  end
  else if Random.bool () then L(l, (addNode g label currentEven (not even)) , d) else
  L(l, g , (addNode d label currentEven (not even)))
   ;;


let createBsp maxHeight maxWidth bspHeight =
  Random.self_init();
    let rec aux node taille nb cEven= 
        if nb <=0  then node 
    else aux (addNode node {coord = Random.int taille ; colored = true }  cEven  true) taille (nb-1) cEven
in

    let rec fill bsp stair = 
    if stair <= bspHeight then
        fill (aux bsp (if stair mod 2 = 0 then maxWidth else maxHeight)  (pow 2 stair) (stair mod 2 = 0 )) (stair+1)
    else bsp
in
 fill (R(None)) 0
;;