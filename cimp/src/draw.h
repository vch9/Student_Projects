

#ifndef CIMP_DRAW_H
#define CIMP_DRAW_H

#include <SDL2/SDL.h>
#include "selection.h"
#include "view.h"
#include "pixel.h"

struct color{
  int r;
  int g;
  int b;
  int a;
}typedef color;


/* Remplace tous les pixels par une couleur donnée */
short fillColor(SDL_Renderer* renderer, SDL_Surface* original, selection* select, struct color* c);

/* Remplace dans la séléction une couleur par une autre avec une marge de tolérance (possible null) */
short replaceColor(SDL_Renderer* renderer, SDL_Surface* original, selection* select, struct color* c1, struct color* c2, int margin);

/* Tableau de fonctions qui modifie un pixel donné */
typedef void (*fptr)(SDL_Surface*, SDL_Surface*, int, int, Uint32*);

/*
    iter sur la séléction une méthode qui modifie la coloration des pixels,
    en récupérant la fonction dans le tableau ptrs[]
*/
short iterDraw(SDL_Renderer* renderer, SDL_Surface* original, selection* select, int index);

#endif //CIMP_DRAW_H
