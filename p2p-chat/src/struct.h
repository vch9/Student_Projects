#ifndef PROJECT_STRUCT_H
#define PROJECT_STRUCT_H
#include <stdint.h>
#include <time.h>
#include <netinet/in.h>
#include "uthash.h"

#define BUFFER_SIZE 1024

enum List{ DATA, N, P_N, INN, FICHIER};

typedef struct LinkedList{
	void* ptr;
	struct LinkedList* next;
	struct LinkedList* prev;
}LinkedList;

typedef struct HeadList{
	LinkedList* head;
	enum List type;
}HeadList;

typedef struct p_neighbours{
	struct in6_addr* addr;
	uint16_t port;
}p_neighbours;

typedef struct neighbours{
	struct in6_addr* addr;
	uint16_t port;

	int pmtu;

	uint8_t* id;
	time_t* hello;
	time_t* long_hello;
}neighbours;

typedef struct innondation{
  struct neighbours* tosend;
  int nb_sent;
  int when;
  time_t* last_time_sent;
}innondation;

typedef struct recent_data{
  uint8_t* id;
  uint8_t* nonce;
  uint8_t size_data;
  uint8_t* data;
  uint8_t type;
  int nb_to_innondate;
  HeadList* innond;
}recent_data;

typedef struct historique{
	uint8_t* id;
	uint8_t* nonce;
}historique;

struct file_struct {
    uint16_t id;
    char file_path[BUFFER_SIZE]; //file_path correspond au nom du fichier pour le cas de la hashmap "downloads"
    struct in6_addr client_addr;
    struct sockaddr_in6 client_sockaddr;
    in_port_t client_port;
    UT_hash_handle hh;
};
#endif //PROJECT_STRUCT_H
