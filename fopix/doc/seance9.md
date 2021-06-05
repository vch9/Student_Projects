Notes de la séance 9 de TransProg M2
====================================

## Exemple complet Kontix -> Javix

En Kontix:

```
DefFun(fact,[x],
  If((==,Var(x),Num(0)),
     Ret(Num(1)),
     /* Un let sans appels de fonction à gauche du let,
        peut devenir un Let de Kontix */
     Let(x',Op(-,Var x, Num 1),
          /* Un let avec un appel de fn à gauche ici fact(x') : */
          PushCont(kont1,[x],
            Call(fact,[x'])))))
            
DefKont(kont1,[x],y,
  Ret(Op(*,Var(x),Var(y))

/* Continuations générées au passage */
DefKont(kont2,[],_,
Let(_,Prim(print_string,[Str("\n")]),
    Ret(Num(0)))
    
DefKont(kont3,[],r,
 Ret(Prim(print_int,[Var(r)])))

/* Et le main Kontix : */
Let(c,Num(10),
  PushCont(kont2,[],
   PushCont(kont3,[],
    Call(fact,[c]))))
```

En javix :

Table des fonctions et continuations:

```
1000 : _ret
1001 : cont2
1002 : cont3
1003 : cont1
```

Et pas besoin de code de label pour `fact` qui est appelé de manière directe

```
/* mise en place du premier K et E */
/* 1000 : _ret */
Push 1000
IStore 0
Push 0
Anewarray
AStore(1) ; première mise en place de E
Push 10
Box
AStore(2) ; maj du contexte des variables
          ; v0 v1 : reservés pour K et E
          ; v2 ici est c
/* Pushcont(cont2,[], ...) */
Push 2
Anewarray
Dup
Push 0
ILoad 0
Box
AAStore  /* mise K dans tableau[0] */
Dup
Push 1
ALoad 1
AAStore  /* mise E dans tableau[1] */
AStore 1 /* mise du nouveau tableau en E */
Push 1001   /* cont2 a le code 1001 */
IStore 0
/* Pushcont(cont3,[], ...) */
Push 2
Anewarray
Dup
Push 0
ILoad 0
Box
AAStore  /* mise K dans tableau[0] */
Dup
Push 1
ALoad 1
AAStore  /* mise E dans tableau[1] */
AStore 1 /* mise du nouveau tableau en E */
Push 1002   /* cont3 a le code 1002 */
IStore 0
/* Call(fact,[c]) */
ALoad 2  /* lecture de c */
AStore 2  /* mise en place du 1er arg de l'appel */
Goto fact
/* fin du main */

fact:
/* ici v0 et v1 sont reservés : K et E
   v2 : 1er arg ici x */
ALoad 2
Unbox
If(Ne,else00)
/* then */
/* RET */
ILoad 0 /* charge K */
Push 1
Box
AStore 2
Goto dispatch
/* fin RET */
else00:
Aload 2
Unbox
Push 1
IOp(Sub)
Box
AStore 3
/* PushCont(kont1,[x], ... */
Push 3
Anewarray
Dup
Push 0
ILoad 0
Box
AAStore  /* mise K dans tableau[0] */
Dup
Push 1
ALoad 1
AAStore  /* mise E dans tableau[1] */
Dup
Push 2
ALoad 2
AAStore /* mise de x dans tableau[2] */
AStore 1 /* mise du nouveau tableau en E */
Push 1003   /* cont1 a le code 1003 */
IStore 0
/* Call(fact,[x']) */
ALoad 3
AStore 2
Goto fact

kont1:
/* v2 c'est y */
/* let [K,E,x] = E */
ALoad 1
Push 0
AALoad
Unbox
IStore 0  /* mise en place de K */
ALoad 1
Push 2
AALoad
AStore 3 /* x est en v3 */
ALoad 1
Push 1
AALoad
AStore 1 /* mise en place de E */
/* corps de kont1 */
ILoad 0 /* K pour le futur RET */
ALoad 3
Unbox
ALoad 2
Unbox
IOp(Mul)
Box
goto dispatch  /* RET(x*y) */

kont2:
/* let [K,E] = E */
ALoad 1
Push 0
AALoad
Unbox
IStore 0  /* mise en place de K */
ALoad 1
Push 1
AALoad
AStore 1 /* mise en place de E */
/* corps de kont2 */
Ldc "\n"
SPrint
/*
Push 0 (pour le unit précedent)
Pop
*/
ILoad 0 /* K pour le futur RET */
Push 0
Box
AStore 2
goto dispatch /* RET(0) */


kont3:
/* let [K,E] = E */
ALoad 1
Push 0
AALoad
Unbox
IStore 0  /* mise en place de K */
ALoad 1
Push 1
AALoad
AStore 1 /* mise en place de E */
/* corps de kont3 */
ILoad 0 /* K pour le futur RET */
ALoad 2
Unbox
IPrint
Push 0 (pour le unit précedent)
goto dispatch /* RET(print_int(r)) */

_ret:
return

dispatch:
tableswitch 1000 [_ret cont2 cont3 cont1] erreur

erreur:
...
```

## Calcul de hauteur de pile

Pendant cette séance, j'ai suggéré de faire ce calcul au moins en
partie sur l'AST Kontix, pour disposer des informations de branches
des `If` et `BIf`. Mais on peut en fait s'en sortir directement sur
le code Javix, j'y reviendrai la prochaine fois. Les remarques
ci-dessous, basées sur Kontix, ne seront donc pas forcément utiles.
A suivre.

#### BIf 

Pour un `BIf((cmp,a1,a2),e1,e2)`, le code obtenu est:

```
calcul de a1
calcul de a2 (avec le resultat de a1 sur la pile)
ificmp else:
calcul de e1
goto end:
else:
calcul de e2
end:
```

Donc la hauteur max de pile est:

```
max (hauteur de pile pour a1,
     1+hauteur de pile pour a2,
     hauteur de pile pour e1
     hauteur de pile pour e2)
```

#### Call

Pour un `Call(f,[a,b,c])`, le code Javix obtenu est:

```
calcul a
calcul b
calcul c
AStore 4
AStore 3
AStore 2
Goto f
```

Donc `hauteur de pile = max (hauteur(a), 1+hauteur(b), 2+hauteur(c))`
