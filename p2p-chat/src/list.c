#include "list.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

HeadList* create(void *ptr, enum List type){
  HeadList* hd = malloc(sizeof(HeadList));
  LinkedList* new = malloc(sizeof(LinkedList));
  new->ptr = ptr;
  new->next = NULL;
  new->prev = NULL;
  hd->head = new;
  hd->type = type;
  return hd;
}
void add_last(void *ptr, HeadList* list){
  if(list==NULL || list->head==NULL) return;
  LinkedList* new = malloc(sizeof(LinkedList));
  LinkedList* aux = list->head;
  new->ptr = ptr;
  new->next = NULL;
  if(list==NULL){
    new->prev = NULL;
    list->head = new;
  }
  else{
    while(aux->next){
      aux = aux->next;
    }
    aux->next = new;
    new->prev = aux;
  }
}
void remove_list(HeadList* list, void* toDel){
  if(list==NULL || list->head==NULL) return;
  LinkedList* aux = list->head;

  short del;
  while(aux){
    del = 0;
    if(list->type==N){
      neighbours* n_l = (neighbours*)aux->ptr;
      neighbours* n_f = (neighbours*)toDel;

      if(memcmp(n_l->addr, n_f->addr, 16)==0 && htons(n_l->port)==htons(n_f->port)){
        del = 1;
      }
    }
    if(list->type==P_N){
      p_neighbours* n_l = (p_neighbours*)aux->ptr;
      p_neighbours* n_f = (p_neighbours*)toDel;
      if(memcmp(n_l->addr, n_f->addr, 16)==0 && htons(n_l->port)==htons(n_f->port))
        del = 1;
    }
    if(list->type==DATA){
      recent_data* d_l = (recent_data*)aux->ptr;
      recent_data* d_f = (recent_data*)toDel;
      if(memcmp(d_l->id, d_f->id, 8)==0 && memcmp(d_l->nonce, d_f->nonce, 4)==0)
        del = 1;
    }
    if(list->type==INN){
      innondation* d_l = (innondation*)aux->ptr;
      innondation* d_f = (innondation*)toDel;
      if(memcmp(d_l->tosend->addr, d_f->tosend->addr, 16)==0 && htons(d_l->tosend->port)==htons(d_f->tosend->port))
        del = 1;
    }
    if(del){
      if(list->type==N){ /* on free tout */
        neighbours* n = (neighbours*)aux->ptr;
        free(n->addr);
        free(n->id);
        free(n->hello);
        free(n->long_hello);
      }
      if(list->type==DATA){
        recent_data* rd = (recent_data*)aux->ptr;
        // free(rd->id);
        free(rd->data);
        free(rd->innond);
      }
      if(aux==list->head){
        if(aux->next==NULL){
          list->head = NULL;
          free(aux->ptr);
          return;
        }
        list->head = aux->next;
        list->head->prev = NULL;
        free(aux->ptr);
        return;
      }
      if(aux->prev!=NULL) aux->prev->next = aux->next;
      if(aux->next!=NULL) aux->next->prev = aux->prev;
      free(aux->ptr);
      return;
    }

    aux = aux->next;
  }
}

void print_list(HeadList* list){
  if(list==NULL || list->head==NULL){
    printf("vide\n");
    return;
  }
  LinkedList* aux = list->head;

  while(aux){
    if(list->type == N){
      char str[INET6_ADDRSTRLEN];
      memset(str, 0, INET6_ADDRSTRLEN);
      neighbours* n = (neighbours*)aux->ptr;
      inet_ntop(AF_INET6, n->addr, str, INET6_ADDRSTRLEN);
      printf("%s ", str);
    }
    aux = aux->next;
  }
  printf("\n");
}
void print_from_end(HeadList* list){
  if(list==NULL || list->head==NULL){
    printf("vide\n");
    return;
  }
  LinkedList* aux = list->head;
  while(aux->next){
    aux = aux->next;
  }
  while(aux){
    // printf("%d ", (int)*aux->ptr);
    aux = aux->prev;
  }
  printf("\n");
}
int len(HeadList* list){
  if(list==NULL || list->head==NULL) return 0;
  LinkedList* aux = list->head;
  int acc = 0;
  while(aux){
    aux = aux->next;
    acc++;
  }
  return acc;
}

// void parcours(HeadList* list){
//   int i = 0;
//   if(list==NULL || list->head==NULL) return;
//   LinkedList* aux = list->head;
//   neighbours* n;
//   char str[INET6_ADDRSTRLEN];
//
//   while(aux){
//     memset(str, 0, INET6_ADDRSTRLEN);
//
//     i++;
//     n = (neighbours*)aux->ptr;
//     inet_ntop(AF_INET6, n->addr, str, INET6_ADDRSTRLEN);
//     printf("%s\n", str);
//
//     if(i==2){
//       remove_list(list, n);
//       printf("jai suppr\n");
//
//     }
//     aux = aux->next;
//   }
//
// }

// int main(){
//   HeadList* voisins = NULL;
//   neighbours* n1 = malloc(sizeof(neighbours));
//   neighbours* n2 = malloc(sizeof(neighbours));
//   neighbours* n3 = malloc(sizeof(neighbours));
//   neighbours* n4 = malloc(sizeof(neighbours));
//
//   uint8_t* id_1 = malloc(8);
//   uint8_t* id_2 = malloc(8);
//   uint8_t* id_3 = malloc(8);
//   uint8_t* id_4 = malloc(8);
//   memcpy(id_1, "aaaaaaaa", 8);
//   memcpy(id_2, "bbbbbbbb", 8);
//   memcpy(id_3, "cccccccc", 8);
//   memcpy(id_4, "dddddddd", 8);
//
//   struct in6_addr* addr1 = malloc(sizeof(struct in6_addr));
//   struct in6_addr* addr2 = malloc(sizeof(struct in6_addr));
//   struct in6_addr* addr3 = malloc(sizeof(struct in6_addr));
//   struct in6_addr* addr4 = malloc(sizeof(struct in6_addr));
//
//   inet_pton(AF_INET6, "28:538:2456::1", addr1);
//   inet_pton(AF_INET6, "::ffff:81.194.27.155", addr2);
//   inet_pton(AF_INET6, "::1", addr3);
//   inet_pton(AF_INET6, "2001:660:3301:9200::51c2:1b9b", addr4);
//
//   n1->id = id_1;
//   n2->id = id_2;
//   n3->id = id_3;
//   n4->id = id_4;
//
//   n1->addr = addr1;
//   n2->addr = addr2;
//   n3->addr = addr3;
//   n4->addr = addr4;
//
//   n1->port = 1;
//   n2->port = 2;
//   n3->port = 3;
//   n4->port = 4;
//
//   n1->hello = NULL;
//   n2->hello = NULL;
//   n3->hello = NULL;
//   n4->hello = NULL;
//
//   n1->long_hello = NULL;
//   n2->long_hello = NULL;
//   n3->long_hello = NULL;
//   n4->long_hello = NULL;
//
//   voisins = create(n1, N);
//   // print_list(voisins);
//
//   add_last(n2, voisins);
//   // print_list(voisins);
//   add_last(n3, voisins);
//   // print_list(voisins);
//   add_last(n4, voisins);
//   // print_list(voisins);
//
//   // remove_list(voisins, n2); print_list(voisins);
//   // remove_list(voisins, n4); print_list(voisins);
//   // remove_list(voisins, n1); print_list(voisins);
//   // remove_list(voisins, n3); print_list(voisins);
//   // add_last(n2, voisins); print_list(voisins);
//
//   return 0;
// }
