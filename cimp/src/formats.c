#include "formats.h"

//format accepte lors de l'export
#define FORMAT_EXPORT ".bmp",".jpeg",".png",".tiff"
#define NB_EXPORT 4

//format accpeté lors du load
#define FORMAT_LOAD ".bmp",".jpeg",".png",".gif",".tga",".xpm",".pnm",".pcx",".tiff",".tif",".lbm",".iff"
#define NB_LOAD 12
//longueur max d'un format en nombre de caractere +'\0'
#define MAX_FORMAT 6


/*
    verifie le format du fichier entrée par l'utilisateur
    lors du chargement "load"
*/
short check_enter_load(char const *tok){
  char tab[NB_LOAD][MAX_FORMAT]={FORMAT_LOAD};
  for(int i=0; i <NB_LOAD; i++){
    if(strstr( tok, tab[i]) !=NULL ){
      printf("format de l'entree valide : " );
      printf("%s\n", tab[i] );
      return 1;
    }
  }
  return 0;
}

/*
    verifie le format du fichier entrée par l'utilisateur
    lors de la sauvegarde "export"
*/
short check_enter_export(char const * tok){
  const char tab[NB_EXPORT][MAX_FORMAT]={FORMAT_EXPORT};
  printf("%s\n", tok );
  for(int i=0; i <NB_EXPORT; i++){
    if( strstr( tok, tab[i] ) != NULL  ){
      printf("format de l'entree valide : " );
      printf("%s\n", tab[i] );
      return 1;
    }
  }
  return 0;
}
