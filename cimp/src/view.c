#include "view.h"
// #include "tools.h"
#include <SDL2/SDL_image.h>
/* Mettre ces variables "global" permet de les rendre accessible plus facilement
   Ici, on ne fait qu'ouvrir la fenêtre. Ce sont d'autre modules qui vont changer son contenu
*/
// LinkedList windows;
SDL_Window *window;
SDL_Renderer *renderer;
SDL_Event event;
extern SDL_Surface* surface;
selection* initSelect = NULL;
SDL_bool scaleMode = SDL_FALSE;

SDL_Window* startView(int width, int height, const char* name) {

    window = SDL_CreateWindow(name, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height,
                              SDL_WINDOW_RESIZABLE);

    if (window == NULL) {
        return 0;
    }
    SDL_SetWindowMaximumSize(window,MAX_SCREEN_WIDTH,MAX_SCREEN_HEIGHT);

    /* Création renderer et surfacce */
    renderer = SDL_CreateRenderer(window, -1, 0);
    surface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
    SDL_FillRect(surface, NULL, SDL_MapRGBA(surface->format, 255, 255, 255, 255));
    putOnRenderer(renderer, surface);

    /* Création de la séléction */
    selection* select = malloc(sizeof(selection));
    select->largeur = width;
    select->hauteur = height;
    short** tab = malloc(sizeof(short*)*MAX_SCREEN_WIDTH);

    for(int i=0; i<MAX_SCREEN_WIDTH; i++){
        tab[i] = malloc(sizeof(short*)*MAX_SCREEN_HEIGHT);
        memset(tab[i], 0, sizeof(tab[i]));
        for(int j=0; j<MAX_SCREEN_HEIGHT; j++){
            if(i<width && j<height)
                tab[i][j] = 1;
        }
    }
    select->tab = tab;
    initSelect = select;

    putOnRenderer(renderer,surface);

    // add(windows, window);

    return window;
}

/* Retourne une copie d'une surface toCopy */
SDL_Surface* copySurface(SDL_Surface* toCopy, int width, int height){
    SDL_Surface* copy = SDL_CreateRGBSurface(toCopy->flags,  width, height, toCopy->format->BitsPerPixel, toCopy->format->Rmask, toCopy->format->Gmask, toCopy->format->Bmask, toCopy->format->Amask);
    SDL_BlitSurface(toCopy, NULL, copy, NULL);
    return copy;
}

/* Retourne une surface transparente sur laquelle on modifie les pixels */
SDL_Surface* createDrawSurface(int width, int height){
    /* Création d'une surface transparente */
    SDL_Surface* toDrawOn = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
    toDrawOn = SDL_ConvertSurfaceFormat(toDrawOn, SDL_PIXELFORMAT_RGBA8888, 0);
    SDL_SetSurfaceBlendMode(toDrawOn, SDL_BLENDMODE_BLEND);

    /* Initialisation surface transparente */
    SDL_FillRect(toDrawOn, NULL, SDL_MapRGBA(toDrawOn->format, 255,0,0, 0));
    return toDrawOn;
}

/* Affiche sur le renderer la surface */
short putOnRenderer(SDL_Renderer* renderer, SDL_Surface* surface){
    int rc;
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);

    SDL_Rect rect = {0,0,surface->w,surface->h};

    SDL_RenderCopy(renderer, texture, NULL, &rect);
    SDL_RenderPresent(renderer);
    return 1;
}

void refreshFocusedWindow(SDL_Window *pWin) {
    window = pWin;
    // surface = SDL_GetWindowSurface(pWin);
    renderer = SDL_GetRenderer(pWin);
    //printf("Current window :%s\n", SDL_GetWindowTitle(pWin));

}

void refreshFocusedWindowByID(Uint32 winID){
    SDL_Window* win = SDL_GetWindowFromID(winID);
    if(!win) printf("Fenêtre innexistante\n");
    refreshFocusedWindow(win);
    //printf("Current window :%s\n", SDL_GetWindowTitle(win));
}
void setBackGround(int w, int h){
    if(!scaleMode){
        initSelect->largeur = w;
        initSelect->hauteur = h;
        cancelSelection(initSelect);


        w = (w>=surface->w)? w : surface->w;
        h = (h>=surface->h)? w : surface->h;

        SDL_Surface* cpy = copySurface(surface,w,h);
        if(surface) SDL_FreeSurface(surface);
        surface = cpy;
    }
    else{
        SDL_Surface* cpy = SDL_CreateRGBSurface(0, w, h, 32, 0, 0, 0, 0);
        SDL_BlitScaled(surface,NULL,cpy,NULL);
        surface = cpy;

    }

    putOnRenderer(renderer,surface);
}
void switchScaleMode() {scaleMode = !scaleMode;};

