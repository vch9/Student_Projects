#include "contact.h"



HeadList* lire_voisin(HeadList* list){
  FILE* f = NULL;
  f = fopen("contact.txt", "r");
  if(f){
    char buf[64];
    memset(buf, 0, 64);
    while(fgets(buf, 64, f)){
      char* q = strtok(buf, " ");
      struct in6_addr* addr = malloc(sizeof(struct in6_addr));
      char ip_peer[INET6_ADDRSTRLEN];
      memset(ip_peer, 0, INET6_ADDRSTRLEN);
      if(strstr(q, ".")){
        sprintf(ip_peer, "::ffff:%s", q); /* ipv4 */
      }
      else{
        sprintf(ip_peer, "%s", q); /* ipv6 */
      }
      inet_pton(AF_INET6, ip_peer, addr->s6_addr);
      q = strtok(NULL, "\n");
      uint16_t port = atoi(q);

      p_neighbours* new = malloc(sizeof(p_neighbours));
      new->addr=addr;
      new->port=htons(port);

      if(list==NULL || list->head==NULL) list = create(new, P_N);
      else add_last(new, list);
      memset(buf, 0 , 64);
    }
    fclose(f);
  }
  return list;
}

void build_contact(HeadList* list){
  if(list==NULL || list->head==NULL) return;
  FILE* f = NULL;
  f = fopen("contact.txt", "w");
  if(f){
    char buf[64];
    char str[INET6_ADDRSTRLEN];
    LinkedList* aux = list->head;
    p_neighbours* p_n;
    while(aux){
      p_n = (p_neighbours*)aux->ptr;
      memset(buf, 0, 64);
      memset(str, 0, INET6_ADDRSTRLEN);
      inet_ntop(AF_INET6, p_n->addr->s6_addr, str, INET6_ADDRSTRLEN);
      sprintf(buf, "%s %d\n", str, p_n->port);
      fputs(buf, f);
      aux = aux->next;
    }
    fclose(f);
  }
}
