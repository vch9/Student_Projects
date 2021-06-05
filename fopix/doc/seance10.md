Notes de la séance 10 de TransProg M2
====================================


## Retour sur le calcul de hauteur maximal de la pile

En fait, on peut procéder directement en parcourant la suite des
instructions Javix. Une simple itération la liste de ces instructions
suffit, même si ce n'est pas forcément l'ordre dans lequel les
instructions seront exécutées.


#### Cas séquentiel

Prenons par exemple: 

```
Push ...
Box
AStore ...
```

Si la pile est vide avant ces instructions:

```
;==> pile vide
Push  // max utilisé par Push : 1 + pile avant (0)
;==> pile de taille 1
Box // max utilisé par Box : 3 + pile avant (1)
;==> pile de taille 1
AStore // max utilisé par AStore : 0 + pile avant 1
;==> pile vide
```

Données à maintenir lors du calcul:
 - taille de pile actuelle
 - pile_max utilisé jusqu'ici
 
A chaque instruction, `pile_max := max(pile_max avant, maxuse(instr)+taille avant)`.

Au final le max des max est 4 ici

#### Code structuré

Que faire des `Goto` et des labels ?

Au moment d'un label de fonction (ou de continuation), la pile est
vide. Pas forcément besoin de s'en assurer, normalement le code qui
précède amènera bien à cette valeur. Pour les autres labels possibles,
à savoir les `elseXYZ` et `endXYZ` des If, voir plus bas.

Au moment d'un `Goto(f)` avec `f` le nom d'une fonction : là encore
la pile sera vide à ce moment-là, on peut s'en assurer si on est
prudent, ou pas si on est optimiste. Cette propriété vient du fait
qu'on finira là une TailExpr de Kontix.

Au moment d'un `Goto dispatch`, la pile contient exactement le code
de label où on veut aller. Ce `Goto dispatch` provient soit d'un `Ret`
soit d'un `Call` indirect. La zone après ce `Goto dispatch` est issu
de la compilation d'un autre TailExpr, on la visite donc avec au
départ une hauteur de pile de 0.

Règle pratique : A la ligne suivant un `Goto dispatch`, passer la
taille de pile courante à 0 (ce qui revient à la faire évoluer de -1).

Ceci suffit à gérer le cas d'un `If_icmp` ou `If` dans un TailExpr.


```
...
...
If...  elseNNN:
...
Goto dispatch // pour un Ret, par exemple
elseNNN:  // ici pile vide de nouveau
...
Goto f  // pile vide 
```

#### Conditionnelle venant d'un BIf de BasicExpr

Quant on compile des BasicExpr, leurs imbrications peuvent faire
monter la hauteur de pile actuelle.


```
...
...
If_icmp ou If  elseNNN:
 ;; si la pile est de hauteur h ici...
...
...  ;; mise en place d'un resultat en haut de pile
 ;; ici hauteur h+1
Goto endXYZ
elseNNN:
 ;; hauteur doit être de nouveau h
...
... ;; mise en place d'un resultat en haut de pile
 ;; ici hauteur h+1
endXYZ:
```

Règle pratique : à la ligne suivant un `Goto endXYZ` on enlève 1 à la
hauteur actuelle pour calculer correctement le max des hauteurs dans
la branche `else`.


## Exemples d'exécutions Kontix

#### fact

```
DefFun(fact,[x],
  If((==,Var(x),Num(0)),
     Ret(Num(1)),
     Let(x',Op(-,Var x, Num 1),
          PushCont(kont1,[x],
            Call(fact,[x'])))))
            
DefKont(kont1,[x],y,
  Ret(Op(*,Var(x),Var(y))
```

Et exécution de `fact(3)` avec la continuation `K0` initiale et l'environnement `E0` (vide):

```
fact(3) avec au lancement K0 et E0 (vide)
= fact(2) avec au lancement K1 = kont1 E1 = [K0,E0,3]
= fact(1) avec au lancement K2 = kont1 E2 = [K1,E1,2]
= fact(0) avec au lancement K3 = kont1 E3 = [K2,E2,1]
= K3(E3,1) = kont1([K2,E2,x=1],y=1)
= K2(E2,1) = kont1([K1,E1,x=2],y=1)
= K1(E1,2) = kont1([K0,E0,x=3],y=2)
= K0(E0,6)
```

#### fib

```
def fib(n) = if (n <= 1) then 1 else fib(n-1) + fib(n-2)
```

en Kontix

```
DefFun(fib,[n],
  If((<=,Var(n),Num(1)),
     Ret(Num(1)),
     Let(n',Op(-,Var n, Num 1),
          PushCont(kont1,[n],
            Call(fib,[n'])))))
            
DefKont(kont1,[n],r1,
     Let(n'',Op(-,Var n, Num 2),
          PushCont(kont2,[r1],
            Call(fib,[n''])))))

DefKont(kont2,[r1],r2,
  Ret(Op(+,Var(r1),Var(r2)))
```

Exécution de `fib(3)` avec les continuations et environnements initiaux `K0` et `E0` :

```
fib(3) avec au lancement K0 et E0 (vide)
fib(2) avec au lancement K1=kont1 et E1=[K0,E0,n=3]
fib(1) avec K2=kont1 E2=[K1,E1,n=2]
K2(E2,1) = kont1([K1,E1,n=2],1)
fib(0) avec K3=kont2 E3=[K1,E1,r1=1)
K3(E3,1) = kont2([K1,E1,r1=1],r2=1)
K1(E1,1+1=2) = kont1([K0,E0,n=3],r1=2)
fib(1) avec K4=kont2 E4=[K0,E0,r1=2]
K4(1) = kont2([K0,E0,r1=2],r2=1)
K0(E0,2+1=3)
```

L'entremêlement des appels à `fib` et des appels de continuations
`cont1` et `cont2` vient de l'aborescence des appels récursifs
(alors qu'un calcul de `fact` est une "ligne" d'appels):

```
     fib(3)
      /  \
  fib(2)  fib(1)
   /  \
fib(1) fib(0)
```

## Exercices sur la récursivité terminale

Voir [Tailrec.md](Tailrec.md) et [Tailrec_solution.md](Tailrec_solution.md)

## La notion de trampoline

Voir [Trampoline.md](Trampoline.md)
