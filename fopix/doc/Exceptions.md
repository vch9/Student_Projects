
# Exceptions et Continuations

Lancer une exception, c'est laisser tomber les calculs en cours et
partir dans un enchaînement de codes permettant de traiter cette
exception (blocs `try ... catch` en Scala, `try ... with` en OCaml).
Cela peut s'implémenter de façon simple en terme de continuations :

  - Au lieu d'une seule continuation `k` comme vu jusqu'à maintenant,
    on en met deux, `k` pour le déroulement standard, et une autre `ke`
    pour un déroulement exceptionnel.

  - Une fonction finit comme d'habitude par des `k(resultat)`, ou bien
    alors une exception est déclenchée quelque part, ce qui revient à
    lancer `ke(mon_exception)`.

  - Un `try...catch` correspond à un `PushCont` sur la continuation
    d'exception `ke`, tandis qu'un `PushCont` usuel n'agit que sur
    `k`, pas `ke`.

Si on a une seule exception dans notre programme, la continuation `ke`
peut prendre en argument un simple `Unit`. Si on a plusieurs
exceptions possibles et/ou que certaine exceptions ont des arguments,
on peut alors concevoir un codage de ces exceptions sous forme de type
somme (`sealed abstract class ... + case class ...` en Scala,
`type ... = ... | ... | ...` en OCaml, blocs avec tags en Fopix, ...).
Et la continuation d'exception `ke` commencera par vérifier quelle
exception elle a reçue.

Il n'est pas demandé de coder ce genre de traitement des exceptions
dans votre projet. Mais vous devez savoir répondre à des exercices
dans le style de ce qui suit.

## Exceptions simples

Ecrire une fonction qui reçoit un tableau d'entiers `t` et sa longueur `n`,
et retourne la multiplication des entiers dans le tableau, en un seul passage
et en évitant de faire la moindre multiplication si 0 est dans le tableau.
Donner d'abord une version par exception, puis une version CPS.

#### Réponse possible

```ocaml
exception Zero

let mult t n =
  let rec loop i =
    if i >= n then 1
    else if t.(i) = 0 then raise Zero
    else t.(i) * loop (i+1)
  in
  try loop 0 with Zero -> 0
```

Et en CPS (ici en utilisant les possibilités de fonctions anonymes d'OCaml):

```
let rec loop t n i k ke =
   if i >= n then k(1)
   else if t.(i) = 0 then ke(Zero)
   else
    let k' = fun res -> k (t.(i) * res)
    in loop t n (i+1) k' ke

let mult t n =
  let k r = r in
  let ke _ = 0 in
  loop t n 0 k ke
```

Faire une CPS compatible avec Fopix (via fonction nommée à toplevel + environnement)
est laissé en exercice...


## Exceptions multiples

Comment compiler le code suivant en une version CPS n'utilisant pas
les exceptions primitives de Scala :

```Scala
class Skip extends Exception
class Stop extends Exception

val f : Int => Int = {
 case 0 => throw new Stop
 case 13 => throw new Skip
 case x => 2*x
}

def loop (t:Array[Int],n:Int,i:Int) : Unit =
  if (i >= n) ()
  else
    try { t(i) = f(t(i)); loop(t,n,i+1) }
    catch {
        case e:Skip => loop(t,n,i+2)
    }

val res = {
 val t = Array(1,13,0,4,0)
 try { loop(t,5,0); t(4) }
 catch {
    case e:Stop => 22
 }
}
```

#### Réponse possible

Note: f a été "inliné" dans loop au passage pour simplifier un peu les choses...

```Scala
sealed abstract class Kind
case class Stop() extends Kind
case class Skip() extends Kind

def loop [T](t:Array[Int],n:Int,i:Int,k:(Unit=>T),ke:(Kind=>T)) : T = {
  if (i >= n) k(())
  else {
    val ke2 : Kind => T = {
      case Skip() => loop(t,n,i+2,k,ke)
      case kind => ke(kind)}
    t(i) match
     { case 0 => ke2(Stop())
       case 13 => ke2(Skip())
       case x => t(i) = 2*x
     }
    loop(t,n,i+1,k,ke2)
    }
  }

val res = {
 val t = Array(1,13,0,4,0)
 val k = (_:Unit) => t(4)
 val ke = (_:Kind) => 22
 loop(t,5,0,k,ke)
}
```
