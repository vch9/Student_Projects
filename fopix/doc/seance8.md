Notes de la séance 8 de TransProg M2
====================================

## Traduction de Kontix en Javix

Dans les grandes lignes, cela va beaucoup ressembler à `Fopix2javix`

Principales différences :

- Le `main` du programme Kontix donne la zone de `main` au début du programme Javix.

- Les variables `v0` et `v1` sont réservées pour toujours contenir une
  continuation K (i.e. un code de label de fonction, bref un entier)
  et un environnement E (i.e. un tableau). Au tout début, on remplira
  `v0` avec une contination initiale (une fonction ne faisant que le `return`
  de Javix) et `v1` avec un environnement initial (un tableau vide).

- Tout appel de fonction aura deux arguments de plus qu'indiqué dans la syntaxe :
  * `v0` contiendra K (la continuation actuelle)
  * `v1` contiendre E (l'environnement actuel)
  * Les arguments normaux seront donc dans les variables `v2` et suivantes.

- La table de saut (zone `dispatch`) est encore là mais uniquement pour les appels
  de fonctions indirects (il n'y a plus du tout de sauts "retour").

- Invariants lors de la compilation concernant la pile :
  * La compilation d'un `TailExpr` donnera du code qui commencera
    toujours son exécution sur une pile totalement vide, et qui finira
    toujours par un saut (i.e. un appel de fonction ou continuation),
    et au moment de ce saut, la pile sera de nouveau vide s'il s'agit
    d'un appel direct ou la pile sera de taille 1 (avec juste le code
    de label) dans le cas d'un appel indirect de fonction / continuation.
  * l'exécution de la compilation d'un BasicExpr donnera en sortie
    une pile identique à son début, sauf un résultat en plus en haut
    de pile.

- En particulier le bloc issu de la compilation d'un `TailExpr` finira
  toujours par une ligne `goto`, et on n'attendra jamais la ligne
  suivant ce bloc, sauf si elle porte un label où on pourra sauter.
  Le bloc issu de la compilation d'un `TailExpr` peut aussi contenir
  plusieurs `goto` donnant plusieurs issues possibles à ce `TailExpr`
  (p.ex. dans le cas d'un `If`).


#### Compilation du If

On parle ici d'un `If` de `TailExpr`, le `BIf` se compilera lui comme
auparavant (cf `Fopix2Javix`). Dans le cas de `TailExpr`, comme le
bloc "then" finira déjà par un saut, on n'a pas besoin de mettre le
`goto label_end_XY` en fin de bloc "then" (et donc pas de label
`label_end_XY` en fin de bloc "else". Bref, pour `If((cmp_op,be1,be2),te1,te2)` :

```javix
Compil(be1)
Compil(be2)
ificmp_INVOP label_else_YZ   ;; avec INVOP l'inverse de cmp_op
Compil(te1)
label_else_YZ:
Compil(te2)
```

#### Let / BLet

R.A.S., on met le resultat du calcul du BasicExpr `be1` dans une variable Javix
`vX` avant de continuer, cf `Fopix2Javix`

#### Call

On s'occupe ici de `Call(be,[a0,...an])`.

Plus de sauvegarde de variable (et encore moins de restauration).
Plus d'adresse de retour !
Attention : `v0` et `v1` reservés pour K et E. Donc `a0` ira en `v2`.

- 1er cas : appel direct, i.e. cas `be = Fun f` :

```
calcul de l'argument 0
calcul de l'argument 1
...
calcul de l'argument n
AStore (n+2)
...
AStore 2
Goto label_f
;zone qui n'est plus atteinte
```

2eme cas : appel indirect, i.e. `be` n'est pas un `Fun` :

```
calcul de be
calcul de l'argument 0
calcul de l'argument 1
...
calcul de l'argument n
AStore (n+2)
...
AStore 2
Goto dispatch ;; avec le resultat du calcul de be sur la pile
;zone qui n'est plus atteinte
```

#### Ret

Un `Ret(be)`, c'est une sorte de `Call(K,[be])` :

```
; Pour récuperer le code de label de K:
ALoad(0)
Unbox
Puis calcul de be
AStore(2) ; resultat de be
Goto dispatch
```

Remarque: comme v0 contiendra toujours un entier (le code du label de la
continuation actuelle), on peut faire une entorse au principe mettant
uniquement des pointeurs ou des entiers boxés dans les variables JVM.
Optimisation possible : décider de toujours mettre dans v0 un entier non boxé.
Dans ce cas, le code précédent devient:

```
ILoad(0)
Calcul de be
AStore(2)
Goto dispatch
```


#### PushCont

Rappel, en pseudo-code un `PushCont(cont,saves,expr)` correspond à :

```
let E = [K,E,...saves...] in
let K = cont in
expr
```

On va donc implémenter ce pseudo-code en Javix:

- Modification de l'environnement courant E (qui est dans `v1`):

```
Push la bonne taille de ce nouvel env
Anewarray
Store dans un temporaire (ou des Dup dans la pile pour garder l'adresse de ce nouveau tableau)
remplir ce tableau:
 - v0 en 1ere case,
 - v1 en deuxième (attention à ne pas avoir déjà écrabouillé v1)
 - et les autres variables dans saves ensuite
Enfin, avec l'adresse du tableau sur la pile,
AStore(1)
```

- Modification de la continuation courante. Si on a choisit de mettre
  dans `v0` un entier non-boxé (cf. auparavant), et que la fonction
  `cont` donne le code de label `XYZ`, alors on fait juste:

```
Push XYZ
IStore(0) ;; sinon sans l'optimisation cela sera Box puis AStore(0)
```

- On continue enfin avec la compilation de la `TailExpr` `expr`.


#### DefCont

Autant `DefFun` n'a rien de spécial, on y met juste la compilation de
son corps (un `TailExpr`), autant pour un `DefCont`, il y a un travail
initial, "ouvrir" l'environnement reçu. C'est le travail contraire
d'un `PushCont`. En pseudo-code:

```
Defcont(kont,[x,y,z],r,expr)
 ==
 def kont(e,r) =
     let [K,E,x,y,z] = e in
     expr
```

en pseudo-Javix:

```
label_kont:
 ; extraire l'environnement e
 v0 <- v1[0] ; changement de K
 v3 <- v1[2] ; mise de x en v3
 v4 <- v1[3] ; mise de y en v4
 v5 <- v1[4] ; mise de z en v5
 ...
 v1 <- v1[1] ; changement de E ;; à bien faire en dernier sinon v1 perdu
 ; v2 contient l'argument r (resultat donné à cette continuation)
 Compil(expr) ; avec la bonne table disant r en v2, x en v3, y en v4 ...
```

#### Mise en place initiale de la continuation et de l'env

Mettre quelque part une fonction `_ret` stoppant juste l'exécution et
rendant la main à la JVM:

```
_ret:
return
```

Les toutes premières instructions de notre code seront donc:

```
Push NNN ; si NNN est le code du label _ret
IStore(0) ; première mise en place de K (si on optimise v0 sans Box)
Push 0
Anewarray
AStore(1) ; première mise en place de E (tableau vide)
Compil(main de kontix)
```

#### Calcul de hauteur de pile

A voir la prochaine fois.
