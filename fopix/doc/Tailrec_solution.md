
# Mise en forme récursive terminale, à la main ou automatiquement

Ceci est une reprise d'un exercice de Programmation Fonctionnelle Avancée (M1).
Soit le type des squelettes d'arbres binaires:

```scala
sealed abstract class Tree
case class Node (lft:Tree,rht:Tree) extends Tree
case object Leaf extends Tree
```

1. Ecrire une fonction Scala testant si l'arbre est parfait (i.e. a toutes ses feuilles à la même profondeur) ?

```
def depth(t:Tree) : Int = {
 t match {
    case Leaf => 0
    case Node(g,d) => 1+Math.max(depth(g),depth(d))
  }
}

def perfect(t:Tree) : Boolean = {
 t match {
    case Leaf => true
    case Node(g,d) => perfect(g) && (perfect(d) && (depth(g) == depth(d)))
 }
}
```

2. Modifier cette fonction (si besoin) pour qu'elle procède de façon
   *linéaire* (un seul parcours d'arbre en tout). Indice: répondre un
   type `Option[Int]`, où `Some(p)` signifie que l'arbre est parfait
   et de profondeur `p`, et `None` signifie arbre imparfait.

```
def depthperfect(t:Tree) : Option[Int] = {
 t match {
    case Leaf => Some(0)
    case Node(g,d) => 
        (depthperfect(g),depthperfect(d)) match {
         case (Some(hg),Some(hd)) => if (hg == hd) Some(hg+1) else None
         case _ => None
         }
    }
}

def perfect(t:Tree) : Boolean = (depthperfect(t) != None)
```


3. Est-ce que ces différentes fonctions sont "naturellement" récursives terminales ?
   Peut-on les réécrire "simplement" pour qu'elles le soient ?

Non pas de réponse simple, il faut remanier l'algorithme (usage d'une
pile d'attente de sous-arbres). Voici par exemple une version 100%
récursive terminale possible, en un seul parcours linéaire de l'arbre:
on stocke des fragments d'arbres avec la profondeur de leur racine, et
à la première feuille qu'on atteint on enregister sa profondeur pour
la comparer avec celle des feuilles ultérieures.

```ocaml
let rec check oprof reste = match reste with
  | [] -> true
  | (p,Node(g,d))::reste -> check oprof ((p+1,g)::(p+1,d)::reste)
  | (p,Leaf)::reste ->
     match oprof with
     | None -> check (Some p) reste
     | Some p' when p = p' -> check oprof reste
     | _ -> false 

let isperfect t = check None [(0,t)]
```

5. Au fait, comment peut-on représenter ces arbres en Fopix ?

```fopix
/* NB:
Leaf = [tag=0]
Node(g,d) = [tag=1,g,d]

None = [tag=0]
Some(x) = [tag=1,x]
*/

def depthperfect(t) =
 if (t[0] == 1) then [1,0]
 else
   let hg = depthperfect(t[1]) in
   if (hg[0] = 0) then [0] /* None */
   else
     let hd = depthperfect(t[2]) in
     if (hd[0] = 0) then [0]
     else
       if hg[1] = hd[1] then [1,hg[1]+1]
       else [0]
```

4. Utiliser l'algorithme de mise en CPS vu en cours, tout d'abord en pseudo-Scala.
6. Donner le code Kontix obtenu.

```kontix
def depthperfect(t) =
 if (t[0] == 1) then Ret [1,0]
 else
   PushCont(Kont1,[t],
    depthperfect(t[1]))
    
DefCont(kont1,[t],hg) =
   if (hg[0] = 0) then Ret [0] /* None */
   else
     PushCont(Kont2,[hg],
      depthperfect(t[2])
      
DefCont(kont2,[hg],hd) =
 Ret (if (hd[0] = 0) then [0]
      else
       if hg[1] = hd[1] then [1,hg[1]+1]
       else [0])
```

7. Peut-on écrire en style récursive terminale une fonction telle que la compilation des expressions Fopix lors de Fopix2Javix ?

Non, pas simplement. Il vaut mieux garder le code dans une forme
lisible même si elle n'est pas récursive terminale, sachant qu'il est
très peu probable que l'AST manipulé par ce genre de fonction soit
extrêmement profond.
