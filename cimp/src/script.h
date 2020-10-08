#ifndef UNTITLED_SCRIPT_H
#define UNTITLED_SCRIPT_H

#include <readline/readline.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <unistd.h>
#include "parser.h"


//ecrit dans un fichier script
void script_write(char * input_file);

//lit un fichier script
void script_read(char * input_file);

//renomme un fichier script
void script_rename(char * input_file, char * rename_file);

// supprime un fichier script
void script_remove(char * input_file);

// supprime une ligne dans le fichier script
void script_rm_ligne(char * input_file, int n);

// execute les commande d'un fichier script
void script_exec(char * input_file);

#endif
