#include "draw.h"
#include <stdio.h>
#include "SDL2/SDL_image.h"
#include "pixel.h"
#include "time.h"

//gcc -g -o TestDraw pixel.c view.c selection.c draw.c testDraw.c $(sdl2-config --cflags --libs) -lSDL2_image
SDL_Surface* surface = NULL;
void randomizeSurface(SDL_Surface* surface, selection* select){
    srand(time(NULL));
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            setPixel(surface, i, j, SDL_MapRGBA(surface->format, rand()%255, rand()%255, rand()%255, rand()%255));
        }
    }
}

short isColored(SDL_Renderer* renderer, SDL_Surface* surface, selection* select, int red, int green, int blue){
    struct color c = {red, green, blue, 255};
    if(fillColor(renderer, surface, select, &c)!=1) return 0;

    for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++)
            if(select->tab[i][j]){
                Uint8 r,g,b,a;
                extractColors(surface, getPixel(surface, i, j), &r, &g, &b, &a);
                if(r!=red || g!=green || b!=blue)
                    return 0;
            }
    return 1;

}

void testFillColor(SDL_Renderer* renderer, SDL_Surface* surface, int width, int height){
    printf("Test fillColor()\n");

    selection* select = NULL;
    printf("BadArgument(1): %d/1\n", fillColor(renderer, surface, select, NULL)==0);

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

    printf("BadArgument(2): %d/1\n", fillColor(NULL, surface, select, NULL)==0);
    printf("BadArgument(3): %d/1\n", fillColor(renderer, NULL, select, NULL)==0);
    printf("BadArgument(4): %d/1\n", fillColor(renderer, surface, select, NULL)==0);
    
    srand(time(NULL));
    for(int i=0; i<10; i++){
        randomizeSurface(surface, select);
        printf("Test(%d): %d/1\n", i+1, isColored(renderer, surface, select, rand()%255, rand()%255, rand()%255));
    }
    
}

short isReplaced(SDL_Renderer* renderer, SDL_Surface* surface, selection* select, struct color c1, struct color c2, int margin){
    long nbToReplace = 0;
    long nbReplaced = 0;
    Uint8 r, r2, r3, g, g2, g3, b, b2, b3, a, a2, a3;
    r = c1.r; g = c1.g; b = c1.b; a = c1.a;
    r3 = c2.r; g3 = c2.g; b3 = c2.b; a3 = c2.a;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            extractColors(surface, getPixel(surface, i, j), &r2, &g2, &b2, &a2);
            if(r2 >= r-margin && r2 <= r+margin)
                if(g2 >= g-margin && g2 <= g+margin)
                    if(b2 >= b-margin && b2 <= b+margin){
                        nbToReplace++;
                    }
            if(r2==r3 && g2==g3 && b2==b3){
                nbReplaced++;
            }
        }
    }
    long stillHere = 0;
    long nowHere = 0;
    if(replaceColor(renderer, surface, select, &c1, &c2, margin)!=1)
        return 0;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            extractColors(surface, getPixel(surface, i, j), &r2, &g2, &b2, &a2);
            if(r2==r3 && g2==g3 && b2==b3)
                nowHere++;
        }
    }

    return nowHere == nbReplaced+nbToReplace;
}

void testReplaceColor(SDL_Renderer* renderer, SDL_Surface* surface, int width, int height){
    printf("Test replaceColor()\n");
    selection* select = NULL;
    struct color c1 = { 128, 128, 128, 255};
    struct color c2 = { 0, 0, 0, 255}; 
    printf("BadArgument(1): %d/1\n", replaceColor(NULL, NULL, select, NULL, NULL, -1)==0);

    /* Création de la séléction */
    select = malloc(sizeof(selection));
    select->largeur = width;
    select->hauteur = height;
    short** tab = malloc(sizeof(short*)*width);

    for(int i=0; i<width; i++){
        tab[i] = malloc(sizeof(short*)*height);
        for(int j=0; j<height; j++){
            tab[i][j] = 1;
        }
    }
    select->tab = tab;


    printf("BadArgument(2): %d/1\n", replaceColor(NULL, NULL, select, NULL, NULL, -1)==0);
    printf("BadArgument(3): %d/1\n", replaceColor(renderer, NULL, select, NULL, NULL, -1)==0);
    printf("BadArgument(4): %d/1\n", replaceColor(renderer, surface, select, NULL, NULL, -1)==0);
    printf("BadArgument(5): %d/1\n", replaceColor(renderer, surface, select, NULL, NULL, 0)==0);
    printf("BadArgument(6): %d/1\n", replaceColor(renderer, surface, select, &c1, NULL, 0)==0);

    srand(time(NULL));
    for(int i=0; i<10; i++){
        randomizeSurface(surface, select);
        printf("Test(%d): %d/1\n", i+1, isReplaced(renderer, surface, select, c1, c2, rand()%255));
    }
   

}

short isNegative(SDL_Renderer* renderer, SDL_Surface* old, SDL_Surface* new, selection* select){
    Uint8 r_old, g_old, b_old, a_old, r_new, g_new, b_new, a_new;
    if(iterDraw(renderer, new, select, 2)!=1) return 0;

    for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++)
            if(select->tab[i][j]){
                extractColors(old, getPixel(old, i, j), &r_old, &g_old, &b_old, &a_old);
                extractColors(new, getPixel(new, i, j), &r_new, &g_new, &b_new, &a_new);
                if(r_new!=255-r_old || g_new!=255-g_old || b_new!=255-b_old)
                    return 0;
            }
    return 1;
}
short isBW(SDL_Renderer* renderer, SDL_Surface* old, SDL_Surface* new, selection* select){
    Uint8 r_old, g_old, b_old, a_old, r_new, g_new, b_new, a_new;
    if(iterDraw(renderer, new, select, 0)!=1) return 0;
    
    for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++)
            if(select->tab[i][j]){
                extractColors(old, getPixel(old, i, j), &r_old, &g_old, &b_old, &a_old);
                extractColors(new, getPixel(new, i, j), &r_new, &g_new, &b_new, &a_new);
                if( ((r_old+g_old+b_old)/3)>122 && (r_new!=255 || g_new!=255 || b_new!=255))
                    return 0;
            }
    return 1;

}
short isGrey(SDL_Renderer* renderer, SDL_Surface* old, SDL_Surface* new, selection* select){
    Uint8 r_old, g_old, b_old, a_old, r_new, g_new, b_new, a_new;
    if(iterDraw(renderer, new, select, 1)!=1) return 0;

     for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++)
            if(select->tab[i][j]){
                extractColors(old, getPixel(old, i, j), &r_old, &g_old, &b_old, &a_old);
                extractColors(new, getPixel(new, i, j), &r_new, &g_new, &b_new, &a_new);
                int grey = (r_old+g_old+b_old)/3;
                if(grey!=r_new || grey!=g_new || grey!=b_new){
                    return 0;    
                }
            }
    return 1;
}
void testIterDraw(SDL_Renderer* renderer, SDL_Surface* surface, int width, int height){
    selection* select = NULL;

    printf("BadArgument(1): %d/1\n", iterDraw(NULL, NULL, NULL, -10)==0);
    printf("BadArgument(2): %d/1\n", iterDraw(renderer, NULL, NULL, -10)==0);
    printf("BadArgument(3): %d/1\n", iterDraw(renderer, surface, NULL, -10)==0);

    /* Création de la séléction */
    select = malloc(sizeof(selection));
    select->largeur = width;
    select->hauteur = height;
    short** tab = malloc(sizeof(short*)*width);

    for(int i=0; i<width; i++){
        tab[i] = malloc(sizeof(short*)*height);
        for(int j=0; j<height; j++){
            tab[i][j] = 1;
        }
    }
    select->tab = tab;

    printf("BadArgument(4): %d/1\n", iterDraw(renderer, surface, select, -10)==0);
    printf("BadArgument(5): %d/1\n", iterDraw(renderer, surface, select, 10)==0);
    
    srand(time(NULL));
    for(int i=0; i<10; i++){
        randomizeSurface(surface, select);
        printf("Test(%d): %d/1\n", i+1, isNegative(renderer, surface, copySurface(surface, width, height), select));
    }
    for(int i=10; i<20; i++){
        randomizeSurface(surface, select);
        printf("Test(%d): %d/1\n", i+1, isBW(renderer, surface, copySurface(surface, width, height), select));
    }
    for(int i=20; i<30; i++){
        randomizeSurface(surface, select);
        printf("Test(%d): %d/1\n", i+1, isGrey(renderer, surface, copySurface(surface, width, height), select));
    }
    
    
}
int main(){
    int width = 150, height = 150;
    SDL_Window *window = SDL_CreateWindow("TestSelection", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height,
                              SDL_WINDOW_RESIZABLE);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_Surface* surface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);

    testFillColor(renderer, surface, width, height);
    printf("----------------------------------\n");
    testReplaceColor(renderer, surface, width, height);
    printf("----------------------------------\n");
    testIterDraw(renderer, surface, width, height);

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);  
}