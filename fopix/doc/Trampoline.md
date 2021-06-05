# Trampolines : compilation de fonctions tailrec dans des langages pauvres

## Pourquoi ?

La technique du *trampoline* permet une compilation (relativement) efficace
de fonctions récursives terminales dans le cas de langages qui ne proposent pas
d'optimisation de ces fonctions (C "historique", Java, Python, JavaScript < 6, ...).
NB: en anglais on parle de langages sans TCO (Tail Call Optimization).
Cela peut également permettre de traiter efficacement les fonctions
tailrec mutuelles en Scala (ce que `@tailrec` ne fait pas).

## Idée

La fonction récursive terminale devient une fonction
non-récursive où chaque sous-appel est remplacé par une donnée
indiquant quoi faire plus tard. Les réponses de la fonction récursive
d'origine sont aussi adaptées. C'est une forme très simplifiée de CPS.
Puis une boucle `while` répète cette fonction non-récursive tant
qu'il reste quelque-chose à faire.

## Exemple

```Scala
/* Code initial (recursif terminal) */
def fact(n:Int,acc:Int) : Int =
  if (n == 0) acc else fact(n-1, n*acc)

def fact_main(n:Int) = fact(n,1)

/* Codage avec un trampoline */

/* type codant l'état actuel du calcul */
sealed abstract class State
case class Stop(res:Int) extends State
case class Next(n:Int,acc:Int) extends State

/* code dérecursifié */
val fact_norec : State => State = {
  case Next(n,acc) => if (n==0) Stop(acc) else Next(n-1,n*acc)
  case st => st /* inutile, juste pour etre exhaustif */
} 

/* La boucle principale du trampoline */
def fact_trampoline (n:Int) = {
  var state : State = Next(n,1)
  while(state.isInstanceOf[Next]) {
    state = fact_norec(state)
  }
  state.asInstanceOf[Stop].res
}
```

Comme on peut le voir, ce style est un peu pénible en Scala,
la valeur `state:State` nécessite soit des `isInstanceOf` et autres
`asInstanceOf` (ou alors des testeurs et accesseurs manuels), ce
qu'on peut d'habitue éviter. Ceci dit, la plupart des codes terminaux
sont inutiles à traiter ainsi en Scala, qui optimise correctement
les fonctions tailrec non-mutuelles (au besoin, forcer cette
optimisation avec l'annotation `@tailrec`). En OCaml, même pas
de `...InstanceOf`, mais même pas besoin de trampolines !

## Fonctions récursives mutuelles

Dans le cas d'une fonction récursive simple, on a stocké
uniquement les prochains arguments. Cette technique se généralise
aux fonctions récursive mutuelles (`f` appelle `g`, qui appelle
`f`, etc). Dans ce cas, il faut aussi indiquer dans `Next`
quelle est la fonction suivante à lancer. Dans un langage
comme C on peut utiliser un pointeur de fonction, et le pointeur
`NULL` indique alors qu'on a fini. Dans d'autre langages
cela peut être une clôture, ou tout autre indicateur
(numéro ou type énuméré sur lequel on fait un `switch` ou
un `match` dans la boucle du trampoline). Voir les liens données en
référence ci-dessous pour plus de détails.

## Efficacité

Cette technique permet bien d'éviter une consommation de
pile proportionnelle à la profondeur d'appels récursifs. On évite donc
les soucis de stack overflow. Et dans les languages où les appels de
fonctions sont coûteux (p.ex. ceux tournant sur la JVM), avec un peu
d'optimisation ("inlining" de fonctions telles que `fact_norec`), on
peut alors se retrouver sans appel de fonction dans le while.

Par contre le trampoline rester généralement plus lent qu'un véritable
traitement natif des tail calls. Par exemple on va allouer des données
(les `Next` ci-dessous). Et pour les langages qui utilisent des clôtures
pour leurs trampolines, ce n'est pas gratuit...

## Quelques liens

  - [Lien wikipedia](https://en.wikipedia.org/wiki/Tail_call#Through_trampolining)
  - [Lien stackoverflow](http://stackoverflow.com/questions/189725/what-is-a-trampoline-function)
  - [Trampolines en Python](http://blog.moertel.com/posts/2013-06-12-recursion-to-iteration-4-trampolines.html)
  - [C et tail calls](https://david.wragg.org/blog/2014/02/c-tail-calls-1.html)
  - [Compilateurs C et tail calls](https://stackoverflow.com/questions/34125/which-if-any-c-compilers-do-tail-recursion-optimization)
