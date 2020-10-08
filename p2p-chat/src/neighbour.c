#include "neighbour.h"

void leaving(int socket, HeadList* n){
  if(n==NULL || n->head==NULL) return;
  LinkedList* aux = n->head;
  neighbours* neigh;
  while(aux){
    neigh = (neighbours*)aux->ptr;
    go_away(socket, neigh->addr, neigh->port, 1, NULL, 0, &neigh->pmtu);
    aux = aux->next;
  }
}


void get_new_neighbours(int socket, uint8_t* my_id, HeadList* n){
  if(n==NULL || n->head==NULL) return;
  LinkedList* aux = n->head;
  p_neighbours* p_n;
  while(aux){
    p_n = (p_neighbours*)aux->ptr;
    send_hello(socket, p_n->addr, p_n->port, my_id, NULL, NULL);
    aux = aux->next;
  }
}
void say_hello(int socket, HeadList* n, uint8_t* my_id){
  if(n==NULL || n->head==NULL) return;
  LinkedList* aux = n->head;
  neighbours* p_n;
  while(aux){
    p_n = (neighbours*)aux->ptr;
    send_hello(socket, p_n->addr, p_n->port, my_id, p_n->id, &p_n->pmtu);
    aux = aux->next;
  }
}
p_neighbours* init_p_neighbour(struct in6_addr from_addr, uint16_t port){
	p_neighbours* new = malloc(sizeof(p_neighbours));
	struct in6_addr* addr = malloc(sizeof(struct in6_addr));

	memcpy(addr, &from_addr, sizeof(from_addr));
	new->addr = addr;

	new->port = htons(port);
	return new;
}
HeadList* add_p_neighbour(struct in6_addr from_addr, uint16_t port, HeadList* list){
  p_neighbours* p_n = init_p_neighbour(from_addr, port);
  if(list==NULL || list->head==NULL) list = create(p_n, P_N);
  else add_last(p_n, list);
  return list;
}
HeadList* remove_old_neighbours(int socket, HeadList* n, HeadList* p_n){
  if(n==NULL || n->head==NULL) return NULL;
	time_t actual_time = time(NULL);
  LinkedList* aux = n->head;
  neighbours* neigh;
  while(aux){ /* normalement ça marche */
    neigh = (neighbours*)aux->ptr;
    if(neigh->hello == NULL || difftime(actual_time, *(neigh->hello))>=120){
      go_away(socket, neigh->addr, neigh->port, 2, NULL, 0, &neigh->pmtu);

      p_neighbours* new = init_p_neighbour(*neigh->addr, neigh->port);
      if(p_n && p_n->head!=NULL) add_last(new, p_n);
      else p_n = create(p_n, P_N);
      remove_list(n, neigh);
    }
    aux = aux->next;
  }
  return p_n;
}
HeadList* actualize_neighbours(int socket, HeadList* n, HeadList* p_n, uint8_t* my_id){
  get_new_neighbours(socket, my_id, p_n);
	say_hello(socket, n, my_id);
	return remove_old_neighbours(socket, n, p_n);
}
void send_to_others(int socket, LinkedList* list){
  LinkedList* aux = list;
  LinkedList* prev = aux->prev;
  neighbours* share = (neighbours*)aux->ptr;

  neighbours* n_to;
  time_t actual_time = time(NULL);
  while(prev){
    n_to = (neighbours*)prev->ptr;
    if(n_to->long_hello && difftime(actual_time, *n_to->long_hello)<=120){
      send_neighbour(socket, share->addr, share->port, n_to->addr->s6_addr, n_to->port, &share->pmtu);
    }
  }
}
void share_neighbours(int socket, HeadList* list_n){
  if(list_n==NULL || list_n->head==NULL) return;
  time_t actual_time = time(NULL);
  LinkedList* aux = list_n->head;
  neighbours* n_from;
  while(aux){
    n_from = (neighbours*)aux->ptr;
    if(n_from->long_hello && difftime(actual_time, *n_from->long_hello)<=120){
      send_to_others(socket, aux);
    }
    aux = aux->next;
  }
}

short is_id_known(uint8_t* sender_id, HeadList* list){
  if(list==NULL || list->head==NULL) return 0;
  LinkedList* aux = list->head;
  neighbours* n;
  while(aux){
    n = (neighbours*)aux->ptr;
    if(memcmp(sender_id, n->id, 8)==0) return 1;
    aux = aux->next;
  }
  return 0;
}

void update_hello(uint8_t* sender_id, int reason, HeadList* list){
  if(list==NULL || list->head==NULL) return;
  LinkedList* aux = list->head;
  neighbours* n;
  while(aux){
    n = (neighbours*)aux->ptr;
    if(memcmp(sender_id, n->id, 8)==0){
      time_t* now = malloc(sizeof(time_t));
      memset(now, 0, sizeof(now));
      time(now);
      n->hello = now;
      if(long_hello){
        n->long_hello = now;
      }
      return;
    }
  }
}

/* Créer un voisin */
struct neighbours* init_neighbour(struct sockaddr_in6* addr, uint8_t* id, time_t* hello){
	struct neighbours* aux = malloc(sizeof(struct neighbours));
	memset(aux, 0, sizeof(aux));

	aux->id = id;
	aux->addr = malloc(sizeof(struct in6_addr));


	memcpy(aux->addr, &addr->sin6_addr, sizeof(addr->sin6_addr));
	memcpy(&aux->port, &addr->sin6_port, sizeof(uint16_t));

	aux->hello = hello;
	aux->long_hello = NULL;
  aux->pmtu = 1232;
  // discover_pmtu(aux);
	return aux;
}

HeadList* add_neighbour(int socket, struct sockaddr_in6* addr, uint8_t* sender_id, HeadList* n){
	uint8_t* id;
	id = malloc(sizeof(uint8_t)*8);
	memcpy(id, sender_id, 8);

	time_t* hello = malloc(sizeof(time_t));
	memset(hello, 0, sizeof(hello));
	time(hello);

  struct neighbours* toAdd = init_neighbour(addr, id, hello);
  if(n==NULL || n->head == NULL){
    n = create(toAdd, N);
  }
  else add_last(toAdd, n);
  return n;
}

short is_neighbour(struct in6_addr addr, in_port_t port, HeadList* list){
  if(list==NULL || list->head==NULL) return 0;
  LinkedList* aux = list->head;
  neighbours* n;
  while(aux){
    n = (neighbours*)aux->ptr;
    if(memcmp(&n->addr, &addr, sizeof(&n->addr))==0 && htons(n->port)==htons((uint16_t)port))
      return 1;
    aux = aux->next;
  }
  return 0;
}


void remove_neighbours(struct in6_addr addr, in_port_t port, HeadList* list){
  if(list==NULL || list->head==NULL) return;
  LinkedList* aux = list->head;
  neighbours* n;
  while(aux){
    n = (neighbours*)aux->ptr;
    if(memcmp(n->addr, &addr, 16)==0 && htons(n->port)==htons((uint16_t)port)){
      remove_list(list, n);
    }

    aux = aux->next;
  }
}

neighbours* find_neighbour(struct in6_addr addr, in_port_t port, HeadList* list){
  if(list==NULL || list->head==NULL) return NULL;
  LinkedList* aux = list->head;
  neighbours* n;
  while(aux){
    n = (neighbours*)aux->ptr;
    if(memcmp(n->addr, &addr, 16)==0 && htons(n->port)==htons((uint16_t)port))
      return n;
    aux = aux->next;
  }
  return NULL;
}
