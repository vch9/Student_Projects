#ifndef CIMP_SELECTION_H
#define CIMP_SELECTION_H

#include <SDL2/SDL.h>
#include "pixel.h"
#include "view.h"
//Une selection sera modéliser par une matrice de booleen

struct selection{
    short** tab;
    int largeur;
    int hauteur;
}typedef selection;

enum Select {Select_ADD, Select_NEW, Select_SUB};



/*
    Cette méthode modifie la structure selection en l'affichant sur le renderer,

    enum Select:
        Select_ADD -> Ajoute a la séléction la nouvelle
        Select_SUB -> Retire de la séléction la nouvelle
        Select_NEW -> Ecrase toute séléction en la remplacent par une nouvelle
 */
short doSelection(SDL_Renderer* renderer, SDL_Surface* original, selection* select, enum Select flags);

/* Vide la séléction */
short cancelSelection(selection* select);
#endif
