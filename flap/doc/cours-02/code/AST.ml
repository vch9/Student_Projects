type t =
  | Nop
  | Assign of identifier * expression
  | Seq of t * t

and expression =
  | EInt of int
  | EId of identifier

and identifier = string
