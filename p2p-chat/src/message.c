#include "message.h"


short send_message(int socket, struct in6_addr* addr, in_port_t port, uint8_t* body, uint16_t length, int* pmtu){
  uint8_t* msg = createMessage(93, 2, length, body);
  struct sockaddr_in6 toSend;
  memset(&toSend, 0, sizeof(toSend));
  toSend.sin6_family = AF_INET6;
  toSend.sin6_port = port;

  toSend.sin6_addr = *addr;

  socklen_t len = sizeof(toSend);
  length = length+4;

  if(pmtu && length>*pmtu){
    length = *pmtu;
  }
  else if(pmtu==NULL && length>PMTU){
    length = PMTU;
  }
  if(sendto(socket, msg, length , 0, (struct sockaddr*)&toSend, sizeof(toSend))<0){
    return 0;
  }
  free(msg);
  return 1;
}
/*
  Envoie un hello a addr,
    Cherche si (ip/port) appartient aux voisins:
      Si his_id == NULL -> envoie d'un hello
      Sinon -> envoie d'un long_hello
*/
short send_hello(int socket, struct in6_addr* addr, in_port_t port, uint8_t my_id[8], uint8_t* his_id, int* pmtu){
  uint8_t* hello;
  if(his_id){ /* Long hello */
    uint8_t body[16];
    memset(body, 0, 16);
    memcpy(body, my_id, 8);
    memcpy(body+8, his_id, 8);
    hello = createTLV(2, 16, body);
    return send_message(socket, addr, port, hello, 18, pmtu);
  }
  else{
    hello = createTLV(2, 8, my_id);
    return send_message(socket, addr, port, hello, 10, pmtu);
  }
  return -1;
}

/* Envoie un go_away avec reason en paramètre, pas de message pour le moment */
short go_away(int socket, struct in6_addr* addr, in_port_t port, int reason, uint8_t* message, int length_message, int* pmtu){
  uint16_t length = 0;
  uint8_t r = (uint8_t)reason;
  uint8_t body[length_message+1];
  memset(body, 0, length_message+1);
  body[0] = r;
  memcpy(body+1, body, length_message);
  uint8_t* go_away = createTLV(6, length_message+1, body);
  length = length + length_message + 3;
  return send_message(socket, addr, port, go_away, length, pmtu);
}

short send_neighbour(int socket, struct in6_addr* addr, in_port_t sender_port, uint8_t ip[16], uint16_t port, int* pmtu){
  uint8_t body[18];
  memset(body, 0, 18);
  memcpy(body, ip, 16);
  memcpy(body+16, &port, 2);
  uint8_t* neighbour = createTLV(3, 20, body);
  uint16_t length = 20;
  return send_message(socket, addr, sender_port, neighbour, length, pmtu);
}

short send_ack(int socket, struct in6_addr* addr, in_port_t port, uint8_t sender_id[8], uint8_t nonce[4], int* pmtu){
  uint8_t body[12];
  memset(body, 0, 12);
  memcpy(body, sender_id, 8);
  memcpy(body+8, nonce, 4);
  uint8_t* ack = createTLV(5, 12, body);
  uint16_t length = 14;
  return send_message(socket, addr, port, ack, length, pmtu);
}

short send_warning(int socket, struct in6_addr* addr, in_port_t port, uint8_t* message, int length_message, int* pmtu){
    uint8_t* warning = createTLV(7, length_message, message);
    uint16_t length = 2+length_message;
    return send_message(socket, addr, port, warning, length, pmtu);
}

short send_data(int socket, struct in6_addr* addr, in_port_t port, uint8_t sender_id[8], uint8_t nonce[4], int type, uint8_t* data, uint8_t length_data, int* pmtu){
  uint8_t body[13+length_data];
  memset(body, 0, 13+length_data);
  memcpy(body, sender_id, 8);
  memcpy(body+8, nonce, 4);
  body[12] = (uint8_t)type;

  memcpy(body+13, data, length_data);
  uint16_t length = 13+length_data;

  uint8_t* data_m = createTLV(4, 13+length_data, body);
  return send_message(socket, addr, port, data_m, length+2, pmtu);
}
