#include "receive_msg.h"

extern int s;
extern HeadList* n;
extern HeadList* p_n;
extern HeadList* rd;
extern historique** histo;
extern int len_histo;
extern char* my_id;
extern char* pseudo;
#define MAX_HISTO 50

short already_received(historique** histo, int len_histo, uint8_t* sender_id, uint8_t* nonce){
  if(histo==NULL) return 0;
	for(int i=0; i<MAX_HISTO; i++){
		if(histo[i] && memcmp(sender_id, histo[i]->id, 8)==0 && memcmp(nonce, histo[i]->nonce, 4)==0)
			return 1;
    }
	return 0;
}

historique** add_histo(historique** histo, int len_histo, uint8_t* sender_id, uint8_t* nonce){
  if(histo==NULL){
    histo = malloc(sizeof(historique)*MAX_HISTO);
  	for(int i=0; i<MAX_HISTO; i++) histo[i]=NULL;
  	len_histo = 0;
  }
	if(len_histo == MAX_HISTO){
		len_histo = 0;
		memcpy(histo[0]->id, sender_id, 8);
		memcpy(histo[0]->nonce, nonce, 4);
	}
	else{
		historique* new = malloc(sizeof(historique));
		new->id = sender_id,
		new->nonce = nonce;
		histo[len_histo] = new;
	}
	len_histo++;
  return histo;
}

void receive_hello(uint8_t* tlv, struct sockaddr_in6* addr){
	uint8_t* sender_id = NULL;
	sender_id = malloc(sizeof(uint8_t)*8);
	memset(sender_id, 0, 8);
	memcpy(sender_id, tlv+2, 8);

	if(is_id_known(sender_id, n)){ /* mettre à jour la date du hello */
		if(tlv[1]==(uint8_t)8){ /* short hello */
			update_hello(sender_id, 0, n);
			free(sender_id);
			sender_id = NULL;
			return;
		}
		else{ /* long hello */
			/* Vérifier que c'est bien mon id */
			if(memcmp(my_id, tlv+10, 8)!=0){
				/* Envoyer un Warning */
				send_warning(s, &addr->sin6_addr, addr->sin6_port, "Not my id", 9, NULL);
				free(sender_id);
				sender_id = NULL;
				return;
			}
			update_hello(sender_id, 1, n);
			free(sender_id);
			sender_id = NULL;
			return;
		}
	}
	else{
		send_hello(s, &addr->sin6_addr, addr->sin6_port, my_id, sender_id, NULL);
		n = add_neighbour(s, addr, sender_id, n);
		free(sender_id);
		sender_id = NULL;
	}
}

void receive_neighbour(uint8_t* tlv, struct sockaddr_in6* addr){
	int length = tlv[1];
	if(length<18){ /* Erreur, pas assez d'informations, send_warning */
		return;
	}
	uint8_t* ip = malloc(sizeof(uint8_t)*16);
	uint16_t port;
	memcpy(ip, tlv+2, 16);
	memcpy(&port, tlv+18, 2);

	/* Ajouter aux voisins potentiels */
	if(is_neighbour(addr->sin6_addr, addr->sin6_port, n)==0){ /* Pour ne pas ajouter un voisin déjà connue */
		struct in6_addr from_addr;
		memset(&from_addr, 0, sizeof(from_addr));
		memcpy(&from_addr.s6_addr, ip, sizeof(ip));
		p_n = add_p_neighbour(from_addr, port, p_n);
	}
	free(ip); ip = NULL;
}

void receive_data(uint8_t* tlv, struct sockaddr_in6* from){
	int length = tlv[1];

	uint8_t* sender_id = malloc(sizeof(uint8_t)*8);
	memset(sender_id, 0, 8);
	memcpy(sender_id, tlv+2, 8);

	uint8_t* nonce = malloc(sizeof(uint8_t)*4);
	memset(nonce, 0, 4);
	memcpy(nonce, tlv+10, 4);

  neighbours* aux = find_neighbour(from->sin6_addr, from->sin6_port, n);
	/* Innondation */
	if(already_received(histo, len_histo, sender_id, nonce)){ /* Si le couple (sender_id, nonce) existe déjà on n'ajoute pas */
    if(aux) send_ack(s, &from->sin6_addr, from->sin6_port, sender_id, nonce, &aux->pmtu);
    else send_ack(s, &from->sin6_addr, from->sin6_port, sender_id, nonce, NULL);
		free(sender_id); sender_id = NULL;
		free(nonce); nonce = NULL;
		return;
	}

	uint8_t type = tlv[14];
	/* Data à partir de tlv+15 */
	if(type==0){
		/* afficher a partir de tlv[15] */
		for(int i=15; i<length+15; i++) printf("%c", tlv[i]);
		printf("\n");
	}

	/* On ajoute aux data a innonder */
	uint8_t* data = malloc(sizeof(uint8_t)*length-13);
	memset(data, 0, length-13);
	memcpy(data, tlv+14, length-13);
 	rd = add_data(type, data, length-13, sender_id, nonce, rd, n);
	add_histo(histo, len_histo, sender_id, nonce);
	if(aux) send_ack(s, &from->sin6_addr, from->sin6_port, sender_id, nonce, &aux->pmtu);
  send_ack(s, &from->sin6_addr, from->sin6_port, sender_id, nonce, NULL);
}

void receive_ack(uint8_t* tlv, struct sockaddr_in6* from){
	uint8_t* sender_id = malloc(sizeof(char)*8);
	uint8_t* nonce = malloc(sizeof(char)*4);
	memset(sender_id, 0, 8);
	memset(nonce, 0, 4);
	memcpy(sender_id, tlv+2, 8);
	memcpy(nonce, tlv+10, 4);

	delete_neighbour_innondation(from, sender_id, nonce, rd);
	sender_id = NULL;
	nonce = NULL;
}

void receive_go_away(uint8_t* tlv, struct sockaddr_in6* addr){
	int length = tlv[1];
	switch(tlv[2]){
		case 0: /* Raison inconnue */
			break;
		case 1: /* Emetteur quitte le réseau */
			break;
		case 2: /* Hello il y a trop longtemps */
			break;
		case 3: /* Emetteur a violé le protocole */
			break;
		default: /* On ignore */
			return;
	}
	/* Supprimer le voisin */
	p_n = add_p_neighbour(addr->sin6_addr, addr->sin6_port, p_n);
	remove_neighbours(addr->sin6_addr, addr->sin6_port, n);
}

void receive_warning(uint8_t* tlv, uint8_t length){
	if(length==0) return;
	for(int i=0; i<length; i++) /* Affichage du warning */
		printf("%c", tlv[i]);
	printf("\n");
}
