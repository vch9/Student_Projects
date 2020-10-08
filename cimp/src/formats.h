#ifndef CIMP_FORMATS_H
#define CIMP_FORMATS_H

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "parser.h"

/*
    verifie le format du fichier entrée par l'utilisateur
    lors du chargement "load"
*/
short check_enter_load(char const *tok);

/* 
    verifie le format du fichier entrée par l'utilisateur
    lors de la sauvegarde "export"
*/
short check_enter_export(char const * tok);

#endif