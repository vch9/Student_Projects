#include "script.h"

/* liste des commandes de script a faire
* ecriture              V      script -w mon_fichier
* lecture               V      script -r mon_fichier
* renommage             V      script -rn mon_fichier new_name
* suppr_ligne           V      script -rl mon_fichier num_ligne
* suppr_fichier         V      script -rm mon_fichier
* execution                    script -e mon_fichier
**/




//entre la commande dans le fichier
void set_line(char * cmd,FILE * fd){
  fprintf(fd, "%s\n",cmd );
}


//test si l'entree est vide ""," "
short check_input(char * cmd){
  char *vide ="";
  if(isspace(*cmd) || isblank(*cmd) || strcmp((cmd),vide)==0  ){
    return 0;
  }else {
    return 1;
  }
}

// effectue la lectuer de toutes les ligne du fichierscript
void lecture(FILE * fd){
  char * cmd=malloc(sizeof(char)*100);
  int acc =1;
  while (fgets(cmd,100,fd)!=NULL ) {
    printf("%8d %s",acc,cmd );
    acc++;
  }
}

//ecrit dans un fichier script
void script_write(char * input_file){
  //ouverture du fichier
  FILE *fp;
  fp=fopen(input_file,"a");
  if(fp == NULL){
    perror("fopen");
  }
  printf("(entrez 'QUIT' pour quitter )\n" );
  // demande d'une commande
  char input_cmd[100];

  // boucle d'édition
  while(1) {
    memset(input_cmd, 0, sizeof(input_cmd));
    fgets(input_cmd, 100, stdin);
    if(strcmp(input_cmd,"QUIT")==0) break;
    //verif de la commmande
    if(check_input(input_cmd)== 0 ){

      printf("mauvaise commande entrée\n" );
    }else{
      //ajout de la commande dans le fichier
      set_line(input_cmd,fp);
    }
  }
  printf("je sors\n");
  //fermeture du fichier
  fclose(fp);
}

//lit un fichier script
void script_read(char * input_file){
  //ouverture du fichier
  FILE *fp;
  fp=fopen(input_file,"r");
  if(fp == NULL){
    printf("le fichier entré n'existe pas\n" );
  }else{
    lecture(fp);
  }
  fclose(fp);

}
//renomme un fichier script
void script_rename(char * input_file, char * rename_file){
  rename(input_file, rename_file);
}
// supprime un fichier script
void script_remove(char * input_file){
  remove(input_file);
}

/*copy src dans dst exceptée la ligne n */
void copy_script(FILE * fp_src, FILE * fp_dst, int n){
  char * cmd = malloc(sizeof(char)*100);
  int cpt = 1;
  while(fgets(cmd,100,fp_src)!=NULL){
    if(cpt != n){
      fprintf(fp_dst, "%s",cmd);//sans "\n" pcq present dans la commande
    }
    cpt++;
  }
}

// supprime une ligne dans le fichier script
void script_rm_ligne(char * input_file, int n){
  //fichier tmp
  char * tmp = malloc(sizeof(char)*20);
  memcpy(tmp,"tmp.script",sizeof("tmp.script"));
  FILE * fp_tmp = malloc(sizeof(FILE));
  fp_tmp = fopen(tmp,"a");//en append

  FILE * fp = malloc(sizeof(FILE));
  fp = fopen(input_file,"r"); // en lecture

  copy_script(fp,fp_tmp,n);
  fclose(fp);
  fclose(fp_tmp);

  script_remove(input_file);
  // sleep(10);

  fp = fopen(input_file,"a");
  fp_tmp = fopen(tmp,"r");
  copy_script(fp_tmp,fp,0);//il suffit de passer 0 pcq on commence a compter a partir de 1
  fclose(fp);
  fclose(fp_tmp);
  script_remove(tmp);
}

// execute les commande d'un fichier script
void script_exec(char * input_file){
  FILE * fp ;
  fp = fopen(input_file, "r");
  char * cmd = malloc(sizeof(char)*100);
  while ( fgets(cmd,100,fp)!=NULL ){
    exec(cmd);
  }
  fclose(fp);
  free(cmd);
}
