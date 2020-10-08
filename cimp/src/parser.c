#include "parser.h"

extern SDL_Renderer* renderer;
SDL_Surface* surface= NULL;
extern selection* initSelect;
extern pixels* m_pixels;
extern SDL_Window* window;

static short nonTermS(char* tokens[], int* p, int size);
static short nonTermSelect(char* tokens[], int* p, int size);
static short nonTermTransform(char* tokens[], int* p, int size);
static short nonTermDraw(char* tokens[], int* p, int size);
static short nonTermMeta(char* tokens[], int* p, int size);
static short nonTermScript(char* tokens[], int* p, int size);


/* nonTermS = Select | Transform | Draw | Meta | Script */
static short nonTermS(char* tokens[], int* p, int size){
    if (size == 0) return 1;
    if(nonTermSelect(tokens, p, size)==1){
        return 1;
    }
    if(nonTermHelp(tokens, p, size)==1){
        return 1;
    }
    if(nonTermTransform(tokens, p, size)!=1){
        if(nonTermDraw(tokens, p, size)!=1){
            if(nonTermMeta(tokens, p, size)!=1){
              /* Autres états à ajouter ici  */
              if(nonTermScript(tokens, p , size)!= 1){
                printf("Commande inconnue\n");
                return 0;
              }

            }
        }
    }
    /* Après l'action on annule la séléction */
    if(initSelect!=NULL)
        cancelSelection(initSelect);
    return 1;
}

/* Select = "" Forme | add Forme | substract Forme */
static short nonTermSelect(char* tokens[], int* p, int size){
    if(*p==size || (strncmp(tokens[*p], "select", strlen("select"))!=0 && strncmp(tokens[*p], "cancel", strlen("cancel"))!=0) ){
        return 0;
    }
    if(initSelect==NULL){
        printf("Sélection impossible\n");
        return 1;
    }
    if(strncmp(tokens[*p], "cancel", strlen("cancel"))==0){
        *p += 1;
        cancelSelection(initSelect);
        return 1;
    }
    *p += 1;
    if(strncmp(tokens[*p], "add", strlen("add"))==0){
        *p += 1;
        doSelection(renderer, surface, initSelect, Select_ADD);
        return 1;
    }
    if(strncmp(tokens[*p], "sub", strlen("sub"))==0){
        *p += 1;
        doSelection(renderer, surface, initSelect, Select_SUB);
        return 1;
    }
    doSelection(renderer, surface, initSelect, Select_NEW);
    // *p += 1;
    return 1;
}
/*
    Draw = fill color
    |   replace c1 c2
    |   negatif
    |   shades_of_grey
    |   black_and_white
*/
static short nonTermDraw(char* tokens[], int* p, int size){
    /* fill r g b */
    if(strncmp(tokens[*p], "fill", strlen("fill"))==0){
        *p += 1;
        if(*p+3<size){
            int r = atoi(tokens[*p]);
            *p += 1;
            int g = atoi(tokens[*p]);
            *p += 1;
            int b = atoi(tokens[*p]);
            *p += 1;
            int a = atoi(tokens[*p]);
            *p += 1;
            struct color c = {r, g, b, a};
            fillColor(renderer, surface, initSelect, &c);
            return 1;
        }
        printf("Argument fill incomplet\n");
        return 1;
    }
    /* replace c1 c2 */
    else if(strncmp(tokens[*p], "replace", strlen("replace"))==0){
        *p += 1;
        if(*p+8<size){ /* roriginal g b */
            int r_1 = atoi(tokens[*p]);
            *p += 1;
            int g_1 = atoi(tokens[*p]);
            *p += 1;
            int b_1 = atoi(tokens[*p]);
            *p += 1;
            int a_1 = atoi(tokens[*p]);
            *p += 1;
            int r_2 = atoi(tokens[*p]);
            *p += 1;
            int g_2 = atoi(tokens[*p]);
            *p += 1;
            int b_2 = atoi(tokens[*p]);
            *p += 1;
            int a_2 = atoi(tokens[*p]);
            *p += 1;
            int margin = atoi(tokens[*p]);
            struct color c1 = {r_1, g_1, b_1, a_1};
            struct color c2 = {r_2, g_2, b_2, a_2};

            replaceColor(renderer, surface, initSelect, &c1, &c2, margin);
            return 1;
        }
        printf("Arguments replace incomplets\n");
        return 1;
    }

    /* negatif */
    else if(strncmp(tokens[*p], "negatif", strlen("negatif"))==0){
        iterDraw(renderer, surface, initSelect, 2);
        return 1;
    }
    /* shades_of_grey */
    else if(strncmp(tokens[*p], "shades_of_grey", strlen("shades_of_grey"))==0){
        iterDraw(renderer, surface, initSelect, 1);
        return 1;
    }
    /* black_and_white */
    else if(strncmp(tokens[*p], "black_and_white", strlen("black_and_white"))==0){
        iterDraw(renderer, surface, initSelect, 0);
        return 1;
    }
    return 0;
}

/*
    Transformation = symetrie axe
    |   rotation n
    |   resize width height
    |   scale width height
    |   copy
    |   cut
    |   paste
*/
static short nonTermTransform(char* tokens[], int* p, int size){
    if(*p==size) return 0;

    /* symetrie axe */
    if (strncmp(tokens[*p], "symetrie", strlen("symetrie")) == 0) {
        *p += 1;
        if(*p<size){
            if(strncmp(tokens[*p], "vertical", strlen("vertical"))==0){
                symetrie(renderer, surface, initSelect, VERTICAL);
                return 1;
            }
            if(strncmp(tokens[*p], "horizontal", strlen("horizontal"))==0){
                symetrie(renderer, surface, initSelect, HORIZONTAL);
                return 1;
            }
            printf("Argument symetrie incomplet\n");
            return 1;
        }
    }
    /* rotation n */
    else if(strncmp(tokens[*p], "rotation", strlen("rotation"))==0){
        *p += 1;
        if(*p<size && isdigit(tokens[*p][0])!=0){
            int angle = atoi(tokens[*p]);

            return rotation(renderer, surface, initSelect, angle);
        }
        printf("Argument rotation incomplet\n");
        return 1;
    }
    /* resize width height */
    else if(strncmp(tokens[*p], "resize", strlen("resize"))==0){
        *p += 1;
        if(*p<size && isdigit(tokens[*p][0])!=0){
            int width = atoi(tokens[*p]);
            *p += 1;
            if(*p<size && isdigit(tokens[*p][0])!=0){
                int height = atoi(tokens[*p]);
                resize(window,width,height);
                return 1;
            }
        }
        printf("Arguments resize incomplets\n");
        return 1;
    }
    /* scale .. */
    else if(strncmp(tokens[*p], "scale", strlen("scale"))==0){
        if(size == 1) {switchScaleMode(); return 1;}
        *p += 1;
        if(*p<size && isdigit(tokens[*p][0])!=0){
            int width = atoi(tokens[*p]);
            *p += 1;
            if(*p<size && isdigit(tokens[*p][0])!=0){
                int height = atoi(tokens[*p]);
                return scale(renderer,surface,initSelect,width,height);
            }
        }
        printf("Arguments scale incomplets\n");
        return 1;
    }
    else if(strncmp(tokens[*p], "copy", strlen("copy"))==0){
        copy_cut(renderer, surface, initSelect, COPY);
        return 1;
    }
    else if(strncmp(tokens[*p], "cut", strlen("cut"))==0){
        copy_cut(renderer, surface, initSelect, CUT);
        return 1;
    }
    else if(strncmp(tokens[*p], "paste", strlen("paste"))==0){
        paste(renderer, surface, initSelect);
        return 1;
    }
    return 0;
}




static short nonTermMeta(char* tokens[], int* p, int size){
  if(*p==size){
      return 0;
  }
  if (strncmp(tokens[*p], "open", strlen("open")) == 0) {
    *p +=1;
    if (*p < size && size > 3) {
        char* name  = tokens[*p];
        *p+=1;
        unsigned int w = atoi(tokens[*p]);
        *p +=1;
        unsigned int h = atoi(tokens[*p]);
        if (MAX_SCREEN_WIDTH < w || MAX_SCREEN_HEIGHT < h)
            printf("Arguments invalides");
        else
            startView(w, h, name);

    }
    else
        printf("Arguments incomplets\n");
    return 1;
  }
  if (strncmp(tokens[*p], "exit", strlen("exit")) == 0) {
    *p +=1;
    threadExit();
    return 1;
  }
  if(strncmp(tokens[*p], "load", strlen("load"))==0){
    *p += 1;
    if (*p <size) {
      if (check_enter_load(tokens[*p])== 1 ) {
        load(tokens[*p],renderer, surface);

        return 1;
      }
      printf("Argument load au format inconnu\n");
      return 1;
    }
    printf("Argument load incomplet\n");
    return 1;
  }
  else if(strncmp(tokens[*p], "export", strlen("export"))==0){
      *p += 1;
      if(*p<size){
          if (check_enter_export(tokens[*p])== 1 ) {
            export(surface,tokens[*p]);
            return 1;
          }
          printf("Argument export au format inconnu\n");
          return 1;
      }
      printf("Argument export incomplet\n");
      return 1;
  }
  return 0;
}

static short nonTermScript(char* tokens[], int* p, int size){
  if(*p==size){
      return 0;
  }
  if( strncmp(tokens[*p],"script", strlen("script")) ==0){
    *p += 1 ;
    if(*p < size ){
      if(check_option_script(tokens[*p]) == 1 ){
        // if( strncmp(tokens[*p],"-w",strlen("-w")) == 0 ){
        //   *p +=1;
        //   script_write(tokens[*p]);
        //   return 1;
        //  }
         if( strncmp(tokens[*p],"-r",strlen("-r")+1) == 0 ){
          *p +=1;
          script_read(tokens[*p]);
          return 1;
        }
        else if( strncmp(tokens[*p],"-rn",strlen("-rn")+1) == 0 ){
          *p +=1;
          if(*p < size && size > 3){
            char * name = tokens[*p];
            *p +=1;
            script_rename(name,tokens[*p]);
            return 1;
          }
          else{
            printf("Arguments incomplets\n" );
            return 1;
          }
        }
        else if( strncmp(tokens[*p],"-rl",strlen("-rl")+1) == 0 ){
          *p +=1;
          if(*p < size && size > 3){
            char * name= tokens[*p];
            *p +=1;
            script_rm_ligne(name, atoi(tokens[*p]));
            return 1;
          }
          else{
            printf("Arguments incomplets\n" );
            return 1;
          }
        }
        else if( strncmp(tokens[*p],"-rm",strlen("-rm")+1) == 0 ){
          *p +=1;
          script_remove(tokens[*p]);
          return 1;
        }
        else if( strncmp(tokens[*p],"-e",strlen("-e")) == 0 ){
          *p +=1;
          script_exec(tokens[*p]);
          return 1;
        }
        return 1;
      }
      else{
        return 0;
      }

    }
  }
  return 0;
}

short exec(char *command) {
    char *tokens[BUF_SIZE];
    int size = 0, p = 0;

    /* Découpage a l'aide de strtok */
    char *q = strtok(command, " ");
    while (q) {
        tokens[size] = q;
        size++;
        q = strtok(NULL, " ");
    }
    nonTermS(tokens, &p, size);
    return 0;
}
