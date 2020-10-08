#ifndef PROJECT_CONTACT_H
#define PROJECT_CONTACT_H
#include <stdio.h>
#include <string.h>
#include "struct.h"
#include "list.h"

/* Rajoute dans le tableau potential_neighbours les voisins enregistrés */
HeadList* lire_voisin(HeadList* list);

/* A la fin de l'éxécution du peer, on ajoute ses voisins potientiels aux contacts */
void build_contact(HeadList* list);

#endif //PROJECT_CONTACT_H
