%{ (* Emacs, open this with -*- tuareg -*- *)
open AST
%}

%token<int> INT
%token<string> ID
%token PLUS STAR SUM LPAREN RPAREN EOF

%start<AST.exp> phrase


%%

phrase: e=exp EOF
{
  e
}

exp: t=term PLUS e=exp
{
  Add (t, e)
}
| t=term
{
  t
}

term: f=factor STAR t=term
{
  Mul (f, t)
}
| f=factor
{
  f
}

factor: x=ID
{
  Id x
}
| x=INT
{
  LInt x
}
| LPAREN e=exp RPAREN
{
  e
}
| SUM LPAREN x=ID e1=exp e2=exp e3=exp RPAREN
{
  Sum (x, e1, e2 ,e3)
}
