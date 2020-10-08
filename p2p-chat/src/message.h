#ifndef PROJECT_MESSAGE_H
#define PROJECT_MESSAGE_H

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include "tlv_builder.h"
#include "time.h"

#define PMTU 1232


/*
  Envoie un hello a addr,
    Cherche si (ip/port) appartient aux voisins:
      Si his_id == NULL -> envoie d'un short_hello
      Sinon -> envoie d'un long_hello
*/
short send_hello(int socket, struct in6_addr* addr, in_port_t port, uint8_t* my_id, uint8_t* his_id, int* pmtu);

/* Envoie un go_away avec reason en paramètre, pas de message pour le moment */
short go_away(int socket, struct in6_addr* addr, in_port_t port, int reason, uint8_t* message, int length_message, int* pmtu);

short send_neighbour(int socket, struct in6_addr* addr, in_port_t sender_port, uint8_t ip[16], uint16_t port, int* pmtu);

short send_warning(int socket, struct in6_addr* addr, in_port_t port, uint8_t* message, int length_message, int* pmtu);

short send_data(int socket, struct in6_addr* addr, in_port_t port, uint8_t sender_id[8], uint8_t nonce[4], int type, uint8_t* data, uint8_t length_data, int* pmtu);

short send_ack(int socket, struct in6_addr* addr, in_port_t port, uint8_t sender_id[8], uint8_t nonce[4], int* pmtu);

short send_message(int socket, struct in6_addr* addr, in_port_t port, uint8_t* body, uint16_t length, int* pmtu);

#endif //PROJECT_MESSAGE_H
