%{
   open AST
%}

%start<AST.t> phrase

%token<int> INT
%token<string> ID
%token EOF ASSIGN SEMICOLON

(* La priorité la plus forte est la plus basse dans le fichier: *)
%left SEMICOLON
%left sequence

%%

phrase: c=command EOF
{
  c
}

command: x=ID ASSIGN e=expression
{
  Assign (x, e)
}
| c1=command SEMICOLON c2=command %prec sequence
{
  Seq (c1, c2)
}

expression: x=ID
{
  EId x
}
| i=INT
{
  EInt i
}

