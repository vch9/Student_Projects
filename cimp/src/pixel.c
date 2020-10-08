#include <SDL2/SDL.h>
#include "pixel.h"

Uint32 getPixel(SDL_Surface *surface, int x, int y){
    int nbOctetsParPixel = surface->format->BytesPerPixel;
    Uint8 *p = (Uint8 *)surface->pixels + y * surface->pitch + x * nbOctetsParPixel;

    switch(nbOctetsParPixel){
        case 1:
            return *p;

        case 2:
            return *(Uint16 *)p;

        case 3:
            if(SDL_BYTEORDER == SDL_BIG_ENDIAN)
                return p[0] << 16 | p[1] << 8 | p[2];
            else
                return p[0] | p[1] << 8 | p[2] << 16;

        case 4:
            return *(Uint32 *)p;

        default:
            return 0; 
    }
}

void setPixel(SDL_Surface *surface, int x, int y, Uint32 pixel){
    int nbOctetsParPixel = surface->format->BytesPerPixel;
    Uint8 *p = (Uint8 *)surface->pixels + y * surface->pitch + x * nbOctetsParPixel;

    switch(nbOctetsParPixel)
    {
        case 1:
            *p = pixel;
            break;

        case 2:
            *(Uint16 *)p = pixel;
            break;

        case 3:
            if(SDL_BYTEORDER == SDL_BIG_ENDIAN)
            {
                p[0] = (pixel >> 16) & 0xff;
                p[1] = (pixel >> 8) & 0xff;
                p[2] = pixel & 0xff;
            }
            else
            {
                p[0] = pixel & 0xff;
                p[1] = (pixel >> 8) & 0xff;
                p[2] = (pixel >> 16) & 0xff;
            }
            break;

        case 4:
            *(Uint32 *)p = pixel;
            break;
    }
}

/* Extrait du pixel ses composants */
void extractColors(SDL_Surface* surf, Uint32 pixel, Uint8* red, Uint8* green, Uint8* blue, Uint8* alpha){
    Uint32 temp;

    /* Récupère valeur rouge du pixel */
    temp = pixel & surf->format->Rmask;  
    temp = temp >> surf->format->Rshift; 
    temp = temp << surf->format->Rloss; 
    *red = (Uint8)temp;

    /* Récupère valeur verte du pixel */
    temp = pixel & surf->format->Gmask; 
    temp = temp >> surf->format->Gshift; 
    temp = temp << surf->format->Gloss;  
    *green = (Uint8)temp;

    /* Récupère valeur bleu du pixel */
    temp = pixel & surf->format->Bmask;  
    temp = temp >> surf->format->Bshift; 
    temp = temp << surf->format->Bloss;  
    *blue = (Uint8)temp;

    /* Récupère valeur alpha du pixel */
    temp = pixel & surf->format->Amask; 
    temp = temp >> surf->format->Ashift; 
    temp = temp << surf->format->Aloss;  
    *alpha = (Uint8)temp;
}