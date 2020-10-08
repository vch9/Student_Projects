#include "draw.h"

/* Remplace tous les pixels par une couleur donnée */
short fillColor(SDL_Renderer* renderer, SDL_Surface* original, selection* select, struct color* c){
    if(renderer==NULL || original==NULL || select==NULL || c==NULL) return 0;
    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;
    /* On extrait les valeurs de color pour le mettre dans le format toDrawOn */

    Uint32 color = SDL_MapRGBA(toDrawOn->format, c->r, c->g, c->b, c->a);
  
    /* On change toute la séléction dans la couleur donnée */
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(select->tab[i][j]){
                setPixel(toDrawOn, i, j, color);
            }
        }
    }

    /* On ajoute toDrawOn sur la copie, puis on l'affiche sur la fenêtre */
    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);

    /* On met a jour l'original */
    SDL_BlitSurface(copy, NULL, original, NULL);

    return 1;
}

/* Remplace dans la séléction une couleur par une autre avec une marge de tolérance (possible null) */
short replaceColor(SDL_Renderer* renderer, SDL_Surface* original, selection* select, struct color* c1, struct color* c2, int margin){
    if(renderer==NULL || original==NULL || select==NULL || c1==NULL || c2==NULL || margin<0) return 0;

    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;

    /* On met dans r,g,b,a les valeurs de toReplace pour les trouver */
    Uint8 r,g,b,a;
    Uint32 replaceBy = SDL_MapRGBA(toDrawOn->format, c2->r, c2->g, c2->b, c2->a);
    Uint8 r_tmp, g_tmp, b_tmp, a_tmp;
    /* On cherche dans la séléction les pixels de couleur toReplace */
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(select->tab[i][j]){
                Uint32 pixel = getPixel(original, i, j);
                extractColors(original, pixel, &r_tmp, &g_tmp, &b_tmp, &a_tmp);
                if(r_tmp >= c1->r-margin && r_tmp <= c1->r+margin)
                    if(g_tmp >= c1->g-margin && g_tmp <= c1->g+margin)
                        if(b_tmp >= c1->b-margin && b_tmp <= c1->b+margin){
                            setPixel(toDrawOn, i, j, replaceBy);
                        }
            }
        }
    }
    /* On ajoute toDrawOn sur la copie, puis on l'affiche sur la fenêtre */
    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);

    /* On met a jour l'original */
    SDL_BlitSurface(copy, NULL, original, NULL);

    return 1;
}

/* Change la séléction en négatif */
void negatif(SDL_Surface* surf, SDL_Surface* toDrawOn, int i, int j, Uint32* tmp){
    /* On récupère le pixel  */
    Uint32 pixel = getPixel(surf, i, j);
    Uint8 r,g,b,a;
    extractColors(surf, pixel, &r, &g, &b, &a);

    /* On modifie le Uint32 avec les valeurs a dessiner */
    *tmp = SDL_MapRGBA(toDrawOn->format, 255-r, 255-g, 255-b, 255);
}

/* Met la séléction en niveaux de gris */
void shades_of_grey(SDL_Surface* surf, SDL_Surface* toDrawOn, int i, int j, Uint32* tmp){
    /* On récupère le pixel  */
    Uint32 pixel = getPixel(surf, i, j);
    Uint8 r,g,b,a;
    extractColors(surf, pixel, &r, &g, &b, &a);

    /* On calcul le niveau de gris en faisant la moyenne de r/g/b */
    int x = (r+g+b)/3;

    /* On modifie le Uint32 avec les valeurs a dessiner */
    *tmp = SDL_MapRGBA(toDrawOn->format, x, x, x, 255);
}

/* Met le pixel en noir ou blanc */
void black_and_white(SDL_Surface* surf, SDL_Surface* toDrawOn, int i, int j, Uint32* tmp){
    /* On récupère le pixel  */
    Uint32 pixel = getPixel(surf, i, j);
    Uint8 r,g,b,a;
    extractColors(surf, pixel, &r, &g, &b, &a);

      /* On regarde si le pixel est plus proche du blanc ou du noir */
    int x = (((r+g+b)/3)>122)?255:0;

    /* On modifie le Uint32 avec les valeurs a dessiner */
    *tmp = SDL_MapRGBA(toDrawOn->format, x, x, x, 255);
}
/* Tableau des fonctions qui modifient un pixel */
fptr ptrs[3] = { black_and_white, shades_of_grey, negatif };

short iterDraw(SDL_Renderer* renderer, SDL_Surface* original, selection* select, int index){
    if(renderer==NULL || original==NULL || select==NULL || index<0 || index>2) return 0;

    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;
    fptr f = ptrs[index];
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(select->tab[i][j]){
                Uint32 tmp;
                f(original, toDrawOn, i, j, &tmp);
                setPixel(toDrawOn, i, j, tmp);
            }
        }
    }

    /* On ajoute toDrawOn sur la copie, puis on l'affiche sur la fenêtre */
    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);

    /* On met a jour l'original */
    SDL_BlitSurface(copy, NULL, original, NULL);

    return 1;
}
