
# Mise en forme récursive terminale, à la main ou automatiquement

Ceci est une reprise d'un exercice de Programmation Fonctionnelle Avancée (M1).
Soit le type des squelettes d'arbres binaires:

```scala
sealed abstract class Tree
case class Node (lft:Tree,rht:Tree) extends Tree
case object Leaf extends Tree
```

1. Ecrire une fonction Scala testant si l'arbre est parfait (i.e. a toutes ses feuilles à la même profondeur) ?
2. Modifier cette fonction (si besoin) pour qu'elle procède de façon *linéaire* (un seul parcours d'arbre en tout). Indice: répondre un type `Option[Int]`, où `Some(p)` signifie que l'arbre est parfait et de profondeur `p`, et `None` signifie arbre imparfait.
3. Est-ce que ces différentes fonctions sont "naturellement" récursives terminales ?
   Peut-on les réécrire "simplement" pour qu'elles le soient ?
4. Utiliser l'algorithme de mise en CPS vu en cours, tout d'abord en pseudo-Scala.
5. Au fait, comment peut-on représenter ces arbres en Fopix ?
6. Donner le code Kontix obtenu.
7. Peut-on écrire en style récursive terminale une fonction telle que la compilation des expressions Fopix lors de Fopix2Javix ?
