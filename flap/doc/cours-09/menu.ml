type meal = Sugar | Chocolate | Cheese

type menu =
| Meal of meal
| Conj of menu * menu
| Disj of menu * menu

let menu = 
  Conj (Disj (Meal Cheese, Meal Sugar),
        Conj (Disj (Meal Chocolate, Meal Cheese),
              Meal Sugar))

module MonadList : sig
  type 'a t (* Les calculs qui s'évaluent en 'a. *)
  val return   : 'a -> 'a t
  val bind     : 'a t -> ('a -> 'b t) -> 'b t
  val pick     : 'a t list -> 'a t
  val fail     : 'a t
  val run      : 'a t -> 'a list
end = struct
  type 'a t = 'a list
  let return x = [x]
  let bind a (f : 'a -> 'b list) =
    List.map f a |> List.flatten
  let pick l = List.concat l
  let run x = x
  let fail = []
end

open MonadList
let ( >>= ) = bind

let rec all : menu -> menu MonadList.t = function
  | (Meal _) as m ->
     return m
  | Conj (m1, m2) ->
     all m1 >>= fun c1 ->
     all m2 >>= fun c2 ->
     return (Conj (c1, c2))
  | Disj (m1, m2) ->
     pick [all m1; all m2]

(** [ (x, y, z) | 
    x + y = z /\ x ∈ [0..10] /\ y ∈ [3..8] /\ z ∈ [6..9]. *)
let rec range start stop =
  if stop < start then
    []
  else 
    return start :: range (start + 1) stop

let ( let* ) = bind

let triples =
  let* x = pick (range 0 10) in
  let* y = pick (range 3 8)  in
  let* z = pick (range 6 9) in
  if x + y = z then return (x, y, z) else fail
