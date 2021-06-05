Notes de la séance 7 de TransProg M2
====================================

## Kontix, suite

Kontix correspond à du code mis en CPS (on y fait donc des "Kontinuations").

Voir [KontixAST.scala](../src/main/scala/trac/kontix/KontixAST.scala).

## Premier exemple complet : fact

#### En Fopix:

```
def fact(x) = if x == 0 then 1 else x * fact(x-1)
val _ = print_int(fact(10))
val _ = print_string("\n")
```

### En Anfix:

```
def fact(x) =
 if x == 0
 then 1
 else 
   let y = 
     (let x' = x-1 in fact(x'))
   in
   x * y
val _ = let r = fact(10) in print_int(r)
val _ = print_string("\n")
```

Ou bien (si on réordonne un peu les `let`, pas obligatoire
ni forcément souhaitable) :

```
def fact(x) =
 if x == 0
 then 1
 else 
   let x' = x-1 in
   let y = fact(x') in
   x * y
val _ = let r = fact(10) in print_int(r)
val _ = print_string("\n")
```

#### En Kontix

Etape 1 : la traduction de fact 

Grosso modo : un Def de Anfix devient un DefFun de Kontix (mais le corps de la fonction est à ajuster pour en faire un TailExpr)

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
```

NB: La règle d'or lors de la traduction de Anfix vers Kontix:

```
CPS(let x = expr1 in expr2)
=
PushCont(kontN,[...vars à sauvegarder...], CPS(expr1))

avec un DefKont en plus à accumuler quelque-part:

DefKont(kontN,[...vars sauvergardés ...], x, CPS(expr2))

où kontN : un nouveau nom de continuation
et [... vars à sauvegarder ... ] sont les variables actuelles utilisées dans expr2 (à part x).
```

Remarque : on peut dans un premier temps traduire systématiquement *tous* les `let` en continuations (mais ça fait certains sauts pour rien). Ici cela donnerait:

```
DefFun(fact,[x],
  If((==,Var(x),Num(1)),
     Ret(Num(1))
     PushCont(kont0,[x],
      Ret (Op(-,Var(x),Num(1)))))
     
DefKont(kont0,[x],x',
  PushCont(kont1,[x],
    Call(fact,[x'])))

DefKont(kont1,[x],y,
  Ret(Op(*,Var(x),Var(y))
```

Dernière chose : le "main", ou comment s'occuper des `Val`...

En anfix de départ:
```
val _ = let r = fact(10) in print_int(r)
val _ = print_string("\n")
```

En une seule expression (de syntaxe Anfix) :

```
let _ = 
  let r = fact(c) in print_int(r)
in
let _ = print_string("\n")
in
0 /* pour simuler un unit */
```

Passage en Kontix

```
/* expression qui servira de main:TailExpr */
Let(c,Num(10),
  PushCont(kont2,[],
   PushCont(kont3,[],
    Call(fact,[c]))))

/* Continuations générées au passage */
DefKont(kont2,[],_,
Let(_,Prim(print_string,[Str("\n")]),
    Ret(Num(0)))
    
DefKont(kont3,[],r,
 Ret(Prim(print_int,[Var(r)])))
```


## Second exemple complet : Fibonacci


#### En Fopix

```
def fib(x) = if x <= 1 then 1
else fib(x-1) + fib(x-2)
```

Les lignes `Val` sont omises ici (même traitement que pour `fact` ci-dessus).

#### En Anfix

```
def fib(x) = if x <= 1 then 1
else
  let r1 = (let y = x-1 in fib(y)) in
  let r2 = (let z = x-2 in fib(z)) in
  r1+r2
```

#### En Kontix

```
DefFun(fib,[x],
 If( (<=,Var(x),Num(1)),
     Ret(Num(1)),
     PushCont(kont1,[x],
      /* à traduire ici : (let y = x-1 in fib(y)) */
      Let(y,Op(-,Var(x),Num(1)),
      Call(fib,[y]))))
      
DefKont(kont1,[x],r1,
   /* à traduire ici :
      let r2 = (let z = x-2 in fib(z)) in
      r1+r2 */
   PushCont(kont2,[r1],
    /* à traduite ici : 
       (let z = x-2 in fib(z)) */
    Let(z,Op(-,Var(x),Num(2)),
      Call(fib,[z]))))
  
DefKont(kont2,[r1],r2,
  Ret(Op(+,Var r1,Var r2))
```

