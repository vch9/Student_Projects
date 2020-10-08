#ifndef PROJECT_DATA_H
#define PROJECT_DATA_H
#include "neighbour.h"
#include <math.h>
#include <stdint.h>
#include "list.h"
#include <sys/socket.h>
#include <netinet/in.h>


#define DATAGRAM_MAX_SIZE 4096

/* On ajoute data a la liste des données à innonder */
HeadList* add_data(uint8_t type, uint8_t* data, int length, uint8_t* id, uint8_t* nonce, HeadList* rd, HeadList* n);

short already_in(uint8_t id[8], uint8_t nonce[4], HeadList* list);

void delete_neighbour_innondation(struct sockaddr_in6* from, uint8_t sender_id[8], uint8_t nonce[4], HeadList* list);

void innondate(int socket, HeadList* rd, time_t* now);

#endif //PROJECT_DATA_H
