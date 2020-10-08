#ifndef CIMP_VIEW_H
#define CIMP_VIEW_H

#include <SDL2/SDL_video.h>
#include <SDL2/SDL_events.h>
#include <SDL2/SDL_render.h>
#include "selection.h"

#define MAX_SCREEN_WIDTH 1080
#define MAX_SCREEN_HEIGHT 1920

// Creer une nouvelle fenêtre
SDL_Window * startView(int width, int height, const char* name);

void threadExit();

/* Retourne une copie d'une surface toCopy */
SDL_Surface* copySurface(SDL_Surface* toCopy, int width, int height);

/* Retourne une surface transparente sur laquelle on modifie les pixels */
SDL_Surface* createDrawSurface(int width, int height);

/* Affiche sur le renderer la surface */
short putOnRenderer(SDL_Renderer* renderer, SDL_Surface* surface);

/* Met à jour le background*/
void setBackGround(int w, int h);

/*active le le mode permettant de redimensionner l'image en meme temps que la fenêtre*/
void switchScaleMode();

/* Met à jour les la fenêtre, le renderer et la surface courante */
void refreshFocusedWindowByID(Uint32 winID);
void refreshFocusedWindow(SDL_Window *pWin);
void refreshSurface(SDL_Surface *temp);

#endif //CIMP_VIEW_H
