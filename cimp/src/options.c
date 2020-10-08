#include "options.h"

// différentes options de la commande 'script'
#define OPTIONS_SCRIPT "-w", "-r", "-rn", "-rl", "-rm", "-e"
// nombres d'options différentes pour la commandes script
#define NB_OPTIONS_SCRIPT 6
// longueur maximale d'une option de script en comptant '\0'
#define MAX_OPTION 4


short check_option_script(char const * tok){
  char tab[NB_OPTIONS_SCRIPT][MAX_OPTION]={OPTIONS_SCRIPT};
  for (size_t i = 0; i < NB_OPTIONS_SCRIPT; i++) {
    if( strncmp(tok, tab[i], strlen(tab[i])+1) == 0 ){
      printf("option de la commande script est valide : " );
      printf("%s\n",tab[i]);
      return 1;
    }
  }
  return 0;
}
