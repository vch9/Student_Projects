#include "selection.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdlib.h>
#include <stdio.h>

/* Afficher sur une copie de la surface la séléction de l'utilisateur */
short afficherSelection(SDL_Renderer* renderer, SDL_Surface* copy, SDL_Surface* toDrawOn, selection* select){
    /* Pour chaque pixel de la séléction, on le récupère, puis nous modifions ses valeurs RGBA */
    Uint32 pixel;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            /* Si select->tab[i][j], alors il appartient a notre séléction et doit être affiché */
            if(select->tab[i][j]){
                pixel = getPixel(toDrawOn, i, j);
                pixel = SDL_MapRGBA(toDrawOn->format, 255, 0, 0, 128);
                setPixel(toDrawOn, i, j, pixel);
            }
        }
    }
    /* On ajoute toDrawOn sur la copie, puis on l'affiche sur la fenêtre */
    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);
    return 1;
}
/* On parcout le tableau de la structure pour copier et modifier les valeurs */
void changeSelection(selection* select, selection* tmp, SDL_Rect rect, enum Select flags){
  for(int i=0; i<select->largeur; i++){
      for(int j=0; j<select->hauteur; j++){
          /* On ajoute des pixels a la séléction */
          if(flags == Select_ADD){
              if(((i>=rect.x && i<=rect.x+rect.w) || (i<=rect.x && i>=rect.x+rect.w)) && ((j>=rect.y && j<=rect.y+rect.h) || (j<=rect.y && j>=rect.y+rect.h)))
                  tmp->tab[i][j] = 1;
              else
                  tmp->tab[i][j] = select->tab[i][j];
          }
          /* On soustrait au tableau les pixels séléctionnés */
          else if(flags == Select_SUB){
              if(((i>=rect.x && i<=rect.x+rect.w) || (i<=rect.x && i>=rect.x+rect.w)) && ((j>=rect.y && j<=rect.y+rect.h) || (j<=rect.y && j>=rect.y+rect.h)))
                  tmp->tab[i][j] = 0;
              else
                  tmp->tab[i][j] = select->tab[i][j];
          }
          /* On crée un nouvelle séléction */
          else{
              if(((i>=rect.x && i<=rect.x+rect.w) || (i<=rect.x && i>=rect.x+rect.w)) && ((j>=rect.y && j<=rect.y+rect.h) || (j<=rect.y && j>=rect.y+rect.h)))

                  tmp->tab[i][j] = 1;
              else
                  tmp->tab[i][j] = 0;
          }
      }
  }
}
/*
    Cette méthode modifie la structure selection en l'affichant sur le renderer,
    enum Select:
        Select_ADD -> Ajoute a la séléction la nouvelle
        Select_SUB -> Retire de la séléction la nouvelle
        Select_NEW -> Ecrase toute séléction en la remplacent par une nouvelle
 */
short doSelection(SDL_Renderer* renderer, SDL_Surface* original, selection* select, enum Select flags){
    if(select==NULL || original==NULL || renderer==NULL) return 0;

    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;

    /*
    SDL_rect et int qui servent a retenir les positions de la séléction de l'utilisateur afin de l'actualiser a chaque frame,
    et de la mettre a jour une fois la séléction terminé
    */
    SDL_Rect rect;
    int x_before, y_before, x_after, y_after;

   
    /*
    SDL_WaitEvent pour attendre SDL_MOUSEBUTTONDOWN qui correspond a la pression du bouton de la souris,
    puis nous attendons que l'utilisateur relache le bouton pour finaliser la séléction
    */
    SDL_Event event;
    while(SDL_WaitEvent(&event)){
        switch(event.type){
            /* L'utilisateur presse le bouton de sa souris */
            case SDL_MOUSEBUTTONDOWN:
                /* On récupère les positions de début */
                x_before = event.button.x;
                y_before = event.button.y;
                while(SDL_WaitEvent(&event)){
                    switch(event.type){
                        case SDL_MOUSEBUTTONUP:
                            x_after = event.button.x;
                            y_after = event.button.y;
                            goto update;
                            break;
                        default:
                            //Rectangle que l'on veut dessiner
                            rect.x = x_before;
                            rect.y = y_before;
                            rect.w = event.button.x - x_before;
                            rect.h = event.button.y - y_before;

                            changeSelection(select, select, rect, flags);
                            SDL_BlitSurface(original, NULL, copy, NULL);
                            SDL_BlitSurface(copy, NULL, toDrawOn, NULL);
                            /* On affiche sur la fenêtre */
                            if(afficherSelection(renderer, copy, toDrawOn, select)!=1)
                              return 0;
                    }
                }
                break;

        }
    }
    update:
        return 1;
}
/* Vide la séléction (c'est à dire une séléction complète) */
short cancelSelection(selection* select){
    if(select==NULL) return 0;
    for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++)
            select->tab[i][j] = 1;
    return 1;
}
