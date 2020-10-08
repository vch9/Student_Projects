#ifndef PROJECT_LIST_H
#define PROJECT_LIST_H
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "struct.h"
#include "neighbour.h"
#include "data.h"



HeadList* create(void *ptr, enum List type);
void add_last(void *ptr, HeadList* list);
void remove_list(HeadList* list, void* toDel);
int len(HeadList* list);

#endif //PROJECT_LIST_H
