#include <tiffio.h>
#include <string.h>
#include <stdio.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include "view.h"
#include "parser.h"
#define QUALITY 100

#ifndef CIMP_META_H
#define CIMP_META_H

struct s_image{
  int width;
  int heigth;
  char * tab;
} t_image;


// short export(SDL_Surface* image, char * const path);
void export(SDL_Surface * image, const char * path);

void load(char *const path, SDL_Renderer* renderer, SDL_Surface* onScreen);


#endif //CIMP_META_H
