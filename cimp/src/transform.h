

#ifndef CIMP_TRANSFORM_H
#define CIMP_TRANSFORM_H

#include <SDL2/SDL.h>
#include "selection.h"
#include "view.h"
#include "pixel.h"

enum axe{VERTICAL, HORIZONTAL}typedef axe;
enum cc{COPY, CUT}typedef cc;

struct pixels{
    Uint32** tab;
    int largeur;
    int hauteur;
}typedef pixels;

/* Inverse la séléction en fonction de l'enum axe: VERTICAL | HORIZONTAL */
short symetrie(SDL_Renderer* renderer, SDL_Surface* original, selection* select, axe axe);

/*Rotation anti-horaire de pi/2*rightAngleCoef */
short rotation(SDL_Renderer *renderer, SDL_Surface *original, selection *select, int rightAngleCoef);

//redimensionne la zonne de travail Zone de travail
short resize(SDL_Window *window, int width, int height);

/*redimensionne la selection */
short scale(SDL_Renderer *renderer, SDL_Surface *original, selection *select, int width, int height);

/* Modifie la matrice pixels avec 3 arguments:
    ccp ->
        COPY: met dans la matrice les pixels de la séléction
        CUT: COPY et enlève les pixels de la surface
*/
short copy_cut(SDL_Renderer* renderer, SDL_Surface* original, selection* select, cc cc);

/* 
    Colle sur la fenêtre la copie, puis l'utilisateur la déplace,
    la confirmation se fait quand SDL_MOUSEBUTTONUP est détécté
*/
short paste(SDL_Renderer* renderer, SDL_Surface* original, selection* select);

#endif //CIMP_TRANSFORM_H
