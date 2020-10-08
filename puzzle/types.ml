open Graphics

type label = { coord : int; colored : bool;}
type bsp = R of color option | L of label * bsp * bsp
type rect = { couleur: color option; xd:int; xf:int; yd:int; yf:int;}
type line = { colored:bool; deb:int * int ; fin:int * int; couleur: color }
