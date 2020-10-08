#ifndef CIMP_PIXEL_H
#define CIMP_PIXEL_H

#include <SDL2/SDL.h>

/* 
    Source des fonctions getPixel() et setPixel() : http://sdz.tdct.org/sdz/modifier-une-image-pixel-par-pixel.html 
*/

Uint32 getPixel(SDL_Surface *surface, int x, int y);
void setPixel(SDL_Surface *surface, int x, int y, Uint32 pixel);

/* Extrait du pixel ses composants */
void extractColors(SDL_Surface* surf, Uint32 pixel, Uint8* red, Uint8* green, Uint8* blue, Uint8* alpha);

#endif //CIMP_PIXEL_H