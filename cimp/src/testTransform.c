#include "transform.h"
#include <stdio.h>
#include "SDL2/SDL_image.h"
#include "pixel.h"
#include "time.h"
//gcc -g -o TestTransform pixel.c view.c selection.c transform.c testTransform.c $(sdl2-config --cflags --libs) -lSDL2_image
extern pixels* m_pixels;
SDL_Surface* surface = NULL;

void randomizeSurface(SDL_Surface* surface, selection* select){
    srand(time(NULL));
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            setPixel(surface, i, j, SDL_MapRGBA(surface->format, rand()%255, rand()%255, rand()%255, rand()%255));
        }
    }
}

short isSymetric(SDL_Renderer* renderer, SDL_Surface* old, SDL_Surface* new, selection* select, axe axe){
    int min = -1, max = -1, middle = -1;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(min==-1 && select->tab[i][j]){
                if(axe==HORIZONTAL) min = j;
                else min = i;
            }
            if(select->tab[i][j]){
                if(axe==HORIZONTAL) max = j;
                else max = i;
            }
        }
    }
    middle = (max+min)/2;
    Uint8 r_old, g_old, b_old, a_old;
    Uint8 r_new, g_new, b_new, a_new;
    if(symetrie(renderer, new, select, axe)!=1) return 0;
    for(int i=0; i<select->largeur-1; i++){
        for(int j=0; j<select->hauteur-1; j++){
            if(select->tab[i][j]){
                extractColors(old, getPixel(old, i, j), &r_old, &g_old, &b_old, &a_old);
                if(axe==HORIZONTAL){
                    if(j>middle) extractColors(new, getPixel(new, i, middle-(j-middle)), &r_new, &g_new, &b_new, &a_new);
                    else extractColors(new, getPixel(new, i, (middle-j)+middle), &r_new, &g_new, &b_new, &a_new);
                }
                else{
                    if(i>middle) extractColors(new, getPixel(new, middle-(i-middle), j), &r_new, &g_new, &b_new, &a_new);
                    else extractColors(new, getPixel(new, (middle-i)+middle, j), &r_new, &g_new, &b_new, &a_new);
                }
                if(r_old!=r_new || g_old!=g_new || b_old!=b_new){
                    return 0;
                }
            }
            else{
                extractColors(old, getPixel(old, i, j), &r_old, &g_old, &b_old, &a_old);
                extractColors(new, getPixel(new, i, j), &r_new, &g_new, &b_new, &a_new);
                if(r_old!=r_new || g_old!=g_new || b_old!=b_new)
                    return 0;

            }
        }
    }
    return 1;
}
void testSymetrie(SDL_Renderer* renderer, SDL_Surface* surface, int width, int height){
    printf("Test symetrie()\n");

    selection* select = NULL;
    printf("BadArgument(1): %d/1\n", symetrie(NULL, NULL, select, HORIZONTAL)==0);
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
    printf("BadArgument(2): %d/1\n", symetrie(renderer, NULL, select, HORIZONTAL)==0);
 
    for(int i=0; i<5; i++){
        randomizeSurface(surface, select);
        axe axe;
        if(rand()%2) axe=VERTICAL;
        else axe=HORIZONTAL;
        SDL_Surface* new = copySurface(surface, select->largeur, select->hauteur);
        printf("Test(%d): %d/1\n", i+1, isSymetric(renderer, surface, new, select, axe));
        SDL_FreeSurface(new);
    }
}
short isCopied(SDL_Renderer* renderer, SDL_Surface* old, selection* select, int copy){
    cc cc;
    if(copy) cc = COPY;
    else cc = CUT;
    SDL_Surface* new = copySurface(old, select->largeur, select->hauteur);
    if(copy_cut(renderer, new, select, cc)!=1)
        return 0;
    Uint8 r, r2, g, g2, b, b2, a, a2;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(select->tab[i][j]){
                if(m_pixels->tab[i][j]==-1) return 0;
                extractColors(new, m_pixels->tab[i][j], &r, &g, &b, &a);
                extractColors(old, getPixel(old, i, j), &r2, &g2, &b2, &a2);
                if(r!=r2 || g!=g2 || b!=b2) return 0;
            }
        }
    }
    return 1;
    SDL_FreeSurface(new);
}
void testCopyCutPaste(SDL_Renderer* renderer, SDL_Surface* surface, int width, int height){
    printf("Test copy_cut_paste()\n");

    selection* select = NULL;
    printf("BadArgument(1): %d/1\n", copy_cut(NULL, NULL, select, COPY)==0);
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
    printf("BadArgument(2): %d/1\n", copy_cut(renderer, NULL, select, COPY)==0);
    for(int i=0; i<5; i++){
        randomizeSurface(surface, select);
        short x = rand()%2;
        printf("Test(%d): %d/1\n", i+1, isCopied(renderer, surface, select, x));
    }

}
int main(){
    int width = 500, height = 500;
    SDL_Window *window = SDL_CreateWindow("TestSelection", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height,
                              SDL_WINDOW_RESIZABLE);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_Surface* surface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);

    
    testSymetrie(renderer, surface, width, height);
    printf("-----------------------------\n");
    testCopyCutPaste(renderer, surface, width, height);
    printf("-----------------------------\n");

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);         
}