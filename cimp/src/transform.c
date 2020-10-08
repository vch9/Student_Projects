#include "transform.h"


/* Inverse la séléction en fonction de l'enum axe: VERTICAL | HORIZONTAL */
short symetrie(SDL_Renderer* renderer, SDL_Surface* original, selection* select, axe axe){
    if(renderer==NULL || original==NULL || select==NULL) return 0;

    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;

    int min = -1, max = -1, middle = -1;
    /* Parcours de séléction pour trouver l'axe de symétrie de la séléction */
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(min==-1 && select->tab[i][j]){
                if(axe==HORIZONTAL) min = j;
                else min = i;
            }
            if(select->tab[i][j]){
                if(j>max && axe==HORIZONTAL) max = j;
                if(i>max && axe==VERTICAL) max = i;
            }
        }
    }

    /* Variables temporaires pour inverser les pixels */
    middle = (max+min)/2;
    Uint32 tmp;
    Uint8 r, g, b, a;
    Uint8 r2, g2, b2, a2;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            /* On inverse les pixels en ne travaillant que sur la moitié des pixels séléctionnés */
            if(select->tab[i][j]){
                extractColors(original, getPixel(original, i, j), &r, &g, &b, &a);
                tmp = SDL_MapRGBA(toDrawOn->format, r, g, b, 255);


                /* On met les pixels a leur position inverse */
                if(axe==HORIZONTAL){
                    if(j>middle) setPixel(toDrawOn, i, middle-(j-middle), tmp);
                    else setPixel(toDrawOn, i, (middle-j)+middle, tmp);
                }
                else{
                    if(i>middle) setPixel(toDrawOn, middle-(i-middle), j, tmp);
                    else setPixel(toDrawOn, (middle-i)+middle, j, tmp);
                }
            }
        }
    }

    /* On ajoute toDrawOn sur la copie, puis on l'affiche sur la fenêtre */
    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);

    /* On met a jour l'original */
    SDL_BlitSurface(copy, NULL, original, NULL);

    return 1;
}

/* Matrice de pixels */
pixels* m_pixels = NULL;

/* Initisialisation en fonction de la séléction */
void init(selection* select){
    m_pixels = malloc(sizeof(pixels));
    m_pixels->largeur = select->largeur;
    m_pixels->hauteur = select->hauteur;

    Uint32** tab = malloc(sizeof(Uint32*)*select->largeur);
    for(int i=0; i<select->largeur; i++){
        tab[i] = malloc(sizeof(Uint32*)*select->hauteur);
        for(int j=0; j<select->hauteur; j++)
            tab[i][j] = -1;
    }

    m_pixels->tab = tab;
}

short apply(SDL_Surface* toDrawOn,SDL_Surface* original , SDL_Surface* copy, SDL_Renderer* renderer){

    /* On ajoute toDrawOn sur la copie, puis on l'affiche sur la fenêtre */
    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);

    /* On met a jour l'original */
    SDL_BlitSurface(copy, NULL, original, NULL);
    return 1;

}

/* Modifie la matrice pixels avec 3 arguments:
    ccp ->
        COPY: met dans la matrice les pixels de la séléction
        CUT: COPY et enlève les pixels de la surface
        PASTE: affiche la matrice sur la surface
*/
short copy_cut(SDL_Renderer* renderer, SDL_Surface* original, selection* select, cc cc){
    if(select==NULL){
        printf("Impossible de copier/coller/couper sans avoir de fenêtre ouverte\n");
        return 0;
    }
    if(renderer==NULL || original==NULL) return 0;

    if(m_pixels==NULL) init(select);
    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;

    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            Uint8 r, g, b, a;
            if(select->tab[i][j]){
                if (cc==COPY){
                    extractColors(original, getPixel(original, i, j), &r, &g, &b, &a);
                    m_pixels->tab[i][j] = SDL_MapRGBA(original->format, r, g, b, a);
                }
                else{
                    extractColors(original, getPixel(original, i, j), &r, &g, &b, &a);
                    m_pixels->tab[i][j] = SDL_MapRGBA(original->format, r, g, b, a);
                    setPixel(toDrawOn, i, j, SDL_MapRGBA(toDrawOn->format, 255, 255, 255, 255));
                }
            }
            else{
                m_pixels->tab[i][j] = -1;
            }
        }
    }

    apply(toDrawOn,original,copy,renderer);
    return 1;
}

/* trouve la position (i,j) de la matrice a copier */
void find_middle(selection* select, int* middle_i, int* middle_j, int* minI, int* maxI,int* minJ,int* maxJ){
    /* On veut le milieu de la zone a copier pour la centrer sur le fenêtre */
    int min_i = -1, min_j = -1, max_i = -1, max_j = -1;
    for(int i=0; i<select->largeur; i++)
        for(int j=0; j<select->hauteur; j++){
            if(select->tab[i][j]){
                if(i>max_i) max_i = i;
                if(j>max_j) max_j = j;
                if(min_i==-1) min_i = i;
                if(min_j==-1) min_j = j;
            }
        }

    /* On a la différence entre le milieu de notre séléction et du milieu de la fenêtre sur on colle */
    *middle_i = (max_i+min_i)/2;
    *middle_j = (max_j+min_j)/2;
    if(minI && minJ && maxI && maxJ){
        *minI = min_i;
        *maxI = max_i;
        *minJ = min_j;
        *maxJ = max_j;
    }
}

/* Affiche les pixels de la matrice copié en fonction de l'entrée utilisateur */
short afficher_copie(SDL_Renderer* renderer, SDL_Surface* copy, SDL_Surface* toDrawOn, selection* select, int diff_i, int diff_j){
    Uint8 r,g,b,a;
    for(int i=0; i<select->largeur; i++){
        for(int j=0; j<select->hauteur; j++){
            if(m_pixels->tab[i][j]!=-1){
                /* on vérifie si ce qu'on copie ne dépasse pas les limites de la fenêtre */
                if(i+diff_i>0 && i+diff_i<select->largeur){
                    if(j+diff_j>0 && j+diff_j<select->hauteur){
                        extractColors(copy, m_pixels->tab[i][j], &r, &g, &b, &a);
                        setPixel(toDrawOn, i+diff_i, j+diff_j, SDL_MapRGBA(toDrawOn->format, r, g, b, 255));
                    }
                }

            }
        }
    }

    SDL_BlitSurface(toDrawOn, NULL, copy, NULL);
    putOnRenderer(renderer, copy);
}
/*
    Colle sur la fenêtre la copie, puis l'utilisateur la déplace,
    la confirmation se fait quand SDL_MOUSEBUTTONUP est détécté
*/
short paste(SDL_Renderer* renderer, SDL_Surface* original, selection* select){
    if(select==NULL){
        printf("Impossible de copier/coller/couper sans avoir de fenêtre ouverte\n");
        return 0;
    }
    if(renderer==NULL || original==NULL) return 0;
    if(m_pixels==NULL) init(select);

    SDL_Surface* copy = copySurface(original, select->largeur, select->hauteur);
    SDL_Surface* toDrawOn = createDrawSurface(select->largeur, select->hauteur);
    if(copy==NULL || toDrawOn==NULL) return 0;

    int middle_i;
    int middle_j;
    find_middle(select, &middle_i, &middle_j,NULL,NULL,NULL,NULL);

    SDL_Event event;
    int current_i = select->largeur/2, current_j= select->hauteur/2;
    afficher_copie(renderer, copy, toDrawOn, select, current_i-middle_i, current_j-middle_j);
    while(SDL_WaitEvent(&event)){
        switch(event.type){
            /* L'utilisateur presse le bouton de sa souris */
            case SDL_MOUSEBUTTONDOWN:
                /* On récupère les positions de début */
                current_i = event.button.x;
                current_j = event.button.y;

                while(SDL_WaitEvent(&event)){
                    switch(event.type){
                        case SDL_MOUSEBUTTONUP: goto update;
                        default:
                            current_i = event.button.x;
                            current_j = event.button.y;
                            int diff_i = current_i - middle_i;
                            int diff_j = current_j - middle_j;

                            SDL_BlitSurface(original, NULL, copy, NULL);
                            SDL_BlitSurface(copy, NULL, toDrawOn, NULL);
                            afficher_copie(renderer, copy, toDrawOn, select, diff_i, diff_j);
                    }
                }
        }
    }
    update:
        /* On met a jour l'original */
        SDL_BlitSurface(copy, NULL, original, NULL);
        return 1;
}

/* créer une surface contenant uniquement les pixels sélectionnés*/
void createSelectedSurface(SDL_Surface *src, SDL_Surface *dst, selection *select);

short rotation(SDL_Renderer *renderer, SDL_Surface *original, selection *select, int rightAngleCoef) {
    if(renderer==NULL || original==NULL || select==NULL) return 0;

    SDL_Surface* toDraw = createDrawSurface(select->largeur,select->largeur);

    createSelectedSurface(original,toDraw,select);


    Uint8 r, g, b, a;
    Uint8 r2, g2, b2, a2;
    Uint32 pixel;
    Uint32 pixel2;
    Uint32 pixel3;
    Uint32 pixel4;

    int middle_i,middle_j, min_i, min_j,max_i,max_j;

    find_middle(select,&middle_i,&middle_j,&min_i,&max_i,&min_j,&max_j);

    int w = max_j-min_j,h = max_i-min_i;//dimension reel de la selection


    //On transforme la selection pour faciliter le calcul
    int square_height = (w>h)? w:h;


    SDL_Surface* croped = createDrawSurface(square_height,square_height);

    SDL_Surface* cropedCpy = createDrawSurface(square_height,square_height);

    SDL_Rect rect = {min_i,min_j,square_height,square_height};

    SDL_BlitSurface(toDraw,&rect,croped, NULL);
    int c = rightAngleCoef%4;

    switch (c){
        case 3:
        case 1:
            while (c--){

                for (int i = 0; i < square_height/2; ++i) {
                    for (int j = i; j < square_height-i-1; ++j) {
                        extractColors(croped, getPixel(croped, i, j), &r, &g, &b, &a);
                        pixel = SDL_MapRGBA(cropedCpy->format, r, g,b,a);

                        extractColors(croped, getPixel(croped, square_height-1-j, i), &r, &g, &b, &a);
                        pixel2 = SDL_MapRGBA(cropedCpy->format, r, g,b,a);
                        setPixel(cropedCpy,i,j,pixel2);


                        extractColors(croped, getPixel(croped, square_height - 1 - i, square_height - 1 - j), &r, &g, &b, &a);
                        pixel3 = SDL_MapRGBA(cropedCpy->format, r, g,b,a);
                        setPixel(cropedCpy,square_height - 1 - j,i,pixel3);

                        extractColors(croped, getPixel(croped, j, square_height - 1 - i), &r, &g, &b, &a);
                        pixel4 = SDL_MapRGBA(cropedCpy->format, r, g,b,a);
                        setPixel(cropedCpy,square_height - 1 - i,square_height - 1 - j,pixel4);



                        setPixel(cropedCpy, j,square_height-1-i,pixel );
                    }
                }
                croped = copySurface(cropedCpy,square_height,square_height);
            }
            SDL_BlitSurface(cropedCpy,NULL,original, &rect);

            return putOnRenderer(renderer,original);

        case 2:

            /* Parcours de séléction pour trouver l'axe de symétrie de la séléction */
            symetrie(renderer,original,select,VERTICAL);
            symetrie(renderer,original,select,HORIZONTAL);
            return 1;
        default:
            break;


    }

    putOnRenderer(renderer,original);

    return 1;
}

/*Change simplement les dimensions de la fenêtre*/
short resize(SDL_Window *window, int width, int height){
    SDL_SetWindowSize(window, width,height);
    setBackGround(width, height);
}

short scale(SDL_Renderer *renderer, SDL_Surface *original, selection *select, int width, int height) {

    //On redessine la surface selectionné
    SDL_Surface* empty = createDrawSurface(select->largeur, select->hauteur);
    Uint8 r, g, b, a;
    Uint32 pixel;
    printf("%d %d\n",select->largeur,select->hauteur);
    int middle_i,middle_j, min_i, min_j,max_i,max_j;

    find_middle(select,&middle_i,&middle_j,&min_i,&max_i,&min_j,&max_j);

    for (int i = 0; i < select->largeur; ++i) {
        for (int j = 0; j <select->hauteur; ++j) {
            if(select->tab[i][j]) {
                extractColors(original, getPixel(original, i, j), &r, &g, &b, &a);
                pixel = SDL_MapRGBA(empty->format, r, g, b, 255);
                setPixel(empty,i,j,pixel);
            }
        }
    }

    SDL_Rect rect = {min_i,min_j,max_i-min_i, max_j-min_j};
    SDL_Rect destRect = {min_i,min_j, width, height};
    SDL_BlitScaled(empty,&rect, original,&destRect);

    return putOnRenderer(renderer, original);
}




void createSelectedSurface(SDL_Surface *src, SDL_Surface *dst, selection *select) {
    Uint8 r, g, b, a;
    Uint32 pixel;
    int x,y;
    for (int i = 0; i < select->largeur; ++i) {
        for (int j = 0; j <select->hauteur; ++j) {
            if(select->tab[i][j]) {

                extractColors(src, getPixel(src, i, j), &r, &g, &b, &a);
                pixel = SDL_MapRGBA(dst->format, r, g, b, 255);
                setPixel(dst,i,j,pixel);

            }
        }
    }
}