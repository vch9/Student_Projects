#ifndef PROJECT_NEIGHBOUR_H
#define PROJECT_NEIGHBOUR_H

#include <stdint.h>
#include <time.h>
#include "list.h"
#include "message.h"
#include "pmtu.h"

/* Prévient du départ */
void leaving(int socket, HeadList* n);

HeadList* actualize_neighbours(int socket, HeadList* n, HeadList* p_n, uint8_t* my_id);

void share_neighbours(int socket, HeadList* list_n);

short is_id_known(uint8_t* sender_id, HeadList* list);

void update_hello(uint8_t* sender_id, int reason, HeadList* n);

HeadList* add_neighbour(int socket, struct sockaddr_in6* addr, uint8_t* sender_id, HeadList* n);

HeadList* add_p_neighbour(struct in6_addr from_addr, uint16_t port, HeadList* list);

short is_neighbour(struct in6_addr addr, in_port_t port, HeadList* list);

void remove_neighbours(struct in6_addr addr, in_port_t port, HeadList* list);

neighbours* find_neighbour(struct in6_addr addr, in_port_t port, HeadList* list);

#endif //PROJECT_NEIGHBOUR_H
