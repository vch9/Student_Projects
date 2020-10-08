//
// Created by benjamin on 28/02/19.
//

#ifndef CIMP_VIEW_H
#define CIMP_VIEW_H
#include <SDL2/SDL_render.h>
#include <SDL2/SDL_events.h>
#include <SDL2/SDL.h>
#include "parser.h"
#include "view.h"

//Cette structure contient toutes les variables partagées dont thread aura besoin
struct mainParameterBlock{
    SDL_bool isEnded;
    SDL_bool hasNewCommand;
    char *command;
}typedef mainParameterBlock;

//p sera de type mainParameterBlock
int startThread(void *p);

void exit();


#endif //CIMP_VIEW_H
