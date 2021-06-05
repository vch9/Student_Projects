Notes de la séance 11 de TransProg M2
=====================================

## Comment les continuations permettent de simuler des exceptions

Voir [Exceptions.md](Exceptions.md)

## Optimisations

Voir [Optims.md](Optims.md)

## Pour aller plus loin : callcc

Facultatif.

Les continuations sont au coeur d'un opérateur assez mystérieux
proposé par certains langages : `callcc`, nom abrégé de
`call-with-current-continuation`. Cet opérateur rend explicite
la continuation actuelle d'un calcul (ce qui est normalement
une donnée interne à l'interpréteur ou au "runtime" du langage).

Voir https://en.wikipedia.org/wiki/Call-with-current-continuation


## Exercice 3 de l'annale 2019

A partir du code récursif terminal suivant:

```ocaml
let rec rev_map f l acc = match l with
| [] -> acc
| x::l’ -> rev_map f l’ (f x :: acc)

let ex = rev_map (fun x -> 2*x) [1;2;3] []
```

on obtient le code suivant basé sur l'idée de trampoline:

```ocaml

type ('a,'b) state =
 | Stop of 'b list
 | Next of ('a -> 'b) * 'a list * 'b list

let rev_map_norec st =
match st with
| Stop _ -> assert false
| Next (f,l,acc) ->
  match l with
  | [] -> Stop acc
  | x::l' -> Next (f,l',(f x :: acc))

let finished = function
| Stop _ -> true
| _ -> false

let rev_map_trampoline f l =
  let st = ref (Next (f,l,[])) in
  while not (finished !st) do
    st := rev_map_norec !st
  done;
  match !st with
  | Stop res -> res
  | Next _ -> assert false
```

La méthode précédente permet de convertir du code récursif terminal en
"while" de manière très systématique.  Mais face à un cas particulier
comme ce rev_map, il est possible de faire plus simple
manuellement. Par exemple en "coupant" l'état en plusieurs références
séparées:

```ocaml
let rev_map_while f l =
  let rl = ref l in
  let racc = ref [] in
  while !rl <> [] do
    match !rl with
    | x::l' -> racc := f x :: !racc; rl := l'
    | [] -> assert false
  done;
  !racc
```
