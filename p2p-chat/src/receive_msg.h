#ifndef PROJECT_RECEIVE_MSG_H
#define PROJECT_RECEIVE_MSG_H
#include "message.h"
#include "struct.h"
#include "data.h"
#include "neighbour.h"
#include "list.h"
#include "client.h"

void receive_hello(uint8_t* tlv, struct sockaddr_in6* addr);
void receive_neighbour(uint8_t* tlv, struct sockaddr_in6* addr);
void receive_data(uint8_t* tlv, struct sockaddr_in6* from);
void receive_ack(uint8_t* tlv, struct sockaddr_in6* from);
void receive_go_away(uint8_t* tlv, struct sockaddr_in6* addr);
void receive_warning(uint8_t* tlv, uint8_t length);

short already_received(historique** histo, int len_histo, uint8_t* sender_id, uint8_t* nonce);
historique** add_histo(historique** histo, int len_histo, uint8_t* sender_id, uint8_t* nonce);

#endif
