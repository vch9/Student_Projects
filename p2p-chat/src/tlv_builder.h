#ifndef PROJECT_TLV_BUILDER_H
#define PROJECT_TLV_BUILDER_H

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>

#define DATAGRAM_MAX_SIZE 4096

//Créer un message à l'adresse msg
uint8_t* createMessage(uint8_t magic, uint8_t version, uint16_t body_length, uint8_t *body);

//Créer un tlv à l'adresse "pTlv"
uint8_t* createTLV(uint8_t type, uint8_t body_length, uint8_t* body);

int short_hello(uint8_t* id, uint8_t *pTlv);

int long_hello(uint64_t source_id, uint64_t dest_id, uint8_t *pTlv);

int neighbour(char* ip, uint16_t port, uint8_t* pTlv);

#endif //PROJECT_TLV_BUILDER_H
