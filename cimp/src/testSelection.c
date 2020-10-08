#include "selection.h"
#include <stdio.h>
#include "SDL2/SDL_image.h"
#include "pixel.h"

//gcc -g -o TestSelection pixel.c view.c selection.c testSelection.c $(sdl2-config --cflags --libs) -lSDL2_image
SDL_Surface* surface = NULL;
/* 
    On considère que si renderer, surface ne sont pas null, 
    ils sont bien construits dans les fonctions auparavant
*/
void testDoSelection(SDL_Renderer* renderer, SDL_Surface* surface, int width, int height){
    printf("Test doSelection()\n");

    selection* select = NULL;
    printf("BadArgument(1): %d/1\n", doSelection(renderer, surface, select, Select_NEW)==0);

    /* Création de la séléction */
    select = malloc(sizeof(selection));
    select->largeur = width;
    select->hauteur = height;
    short** tab = malloc(sizeof(short*)*width);

    for(int i=0; i<width; i++){
        tab[i] = malloc(sizeof(short*)*height);
        for(int j=0; j<height; j++)
            tab[i][j] = 1;
    }
    select->tab = tab;

    printf("BadArgument(2): %d/1\n", doSelection(NULL, surface, select, Select_NEW)==0);
    printf("BadArgument(3): %d/1\n", doSelection(renderer, NULL, select, Select_NEW)==0);
    printf("GoodArgument: %d/1\n", doSelection(renderer, surface, select, Select_NEW)==1);

    printf("-----------------------------\n");
}
void testCancelSelection(int width, int height){
    printf("Test cancelSelection()\n");

    selection* select = NULL;
    printf("BadArgument: %d/1\n", cancelSelection(select)==0);
    
    /* Création de la séléction */
    select = malloc(sizeof(selection));
    select->largeur = width;
    select->hauteur = height;
    short** tab = malloc(sizeof(short*)*select->largeur);

    for(int i=0; i<select->largeur; i++){
        tab[i] = malloc(sizeof(short*)*select->hauteur);
        for(int j=0; j<select->hauteur; j++)
            if( (i+j)%2==0 )
                tab[i][j] = 1;
            else
                tab[i][j] = 0;
    }
    select->tab = tab;

    printf("GoodArgument: %d/1\n", cancelSelection(select));
    short vide = 1;
    for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++)
            if(select->tab[i][j]!=1)
                vide = 0;

    printf("videSelection: %d/1\n", vide);

    printf("-----------------------------\n");
}

int main(){
    int width = 500, height = 500;
    SDL_Window *window = SDL_CreateWindow("TestSelection", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height,
                              SDL_WINDOW_RESIZABLE);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_Surface* surface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);

    
    testDoSelection(renderer, surface, width, height);
    testCancelSelection(width, height);

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);         
}