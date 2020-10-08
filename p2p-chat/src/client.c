#include "client.h"

int s, rc;

HeadList* n = NULL;
HeadList* p_n = NULL;
HeadList* rd = NULL;

historique** histo = NULL;
int len_histo;

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

char* my_id = NULL;
char* pseudo = NULL;


void* innondate_thread(void *ptr){
	time_t* now = malloc(sizeof(time_t));
	memset(now, 0, sizeof(now));
	while(1){
		sleep(2);
		pthread_mutex_lock(&lock);
		time(now);
		innondate(s, rd, now);
		pthread_mutex_unlock(&lock);
	}
}
void clean(){
	build_contact(p_n);
	if(n && n->head){
		LinkedList* aux_n = n->head;
		while(aux_n && aux_n->ptr){
			neighbours* nei = (neighbours*)aux_n->ptr;
			free(nei->addr);
			free(nei->id);
			free(nei->hello);
			free(nei->long_hello);
			free(nei);
			aux_n = aux_n->next;
		}
	}
	if(rd && rd->head){
		LinkedList* aux_d = rd->head;
		while(aux_d && aux_d->ptr){
			recent_data* d = (recent_data*)aux_d->ptr;
			free(d->id);
			free(d->data);
			free(d->innond);
			free(d);
			aux_d = aux_d->next;
		}
	}
	if(p_n && p_n->head){
		LinkedList* aux_pn = p_n->head;
		while(aux_pn && aux_pn->ptr){
			p_neighbours* p_nei = (p_neighbours*)aux_pn->ptr;
			free(p_nei->addr);
			free(p_nei);
			aux_pn = aux_pn->next;
		}
	}
}
void* read_input_user(void *ptr){
	char input[1096];
	while(1){
		memset(input, 0, 1096);
		fgets(input, sizeof(input), stdin);
		pthread_mutex_lock(&lock);
		if(input[0]=='q' && strlen(input)==2){
			leaving(s, n);
			clean();
			pthread_mutex_unlock(&lock);
			exit(1);
		}
		else if(input[0] == '!'){
			char * str = strtok(input, " ");
			if (strcmp(str, "!send") ==0){
				str = strtok(NULL,"\n");
				if(n && n->head){
					LinkedList* aux = n->head;
					while(aux){
						neighbours* neigh = (neighbours*)aux->ptr;

						histo = send_upload_request(str, s, neigh->addr, neigh->port, neigh->id, &neigh->pmtu, histo, len_histo );

						aux = aux->next;
					}
				}
				pthread_mutex_unlock(&lock);
			}
			else if(strcmp(str, "!dl") ==0){
				str = strtok(NULL,"\n");
				if(str){
					uint16_t id = (uint16_t) atoi(str);
					accept_file(id);
				}
			}
			pthread_mutex_unlock(&lock);
		}
		else{
			int l_pseudo = strlen(pseudo);
			int l_input = strlen(input);
			uint8_t* data = malloc(sizeof(uint8_t)*(l_pseudo+l_input+2));
			memset(data, 0, l_pseudo+l_input);
			memcpy(data, pseudo, l_pseudo);
			memcpy(data+l_pseudo, input, l_input);

			uint8_t* nonce = malloc(sizeof(uint8_t)*4);
			for(int i=0; i<4; i++)
				nonce[i] = rand()%255;
			for(int i=0; i<l_pseudo+l_input-1; i++) printf("%c", data[i]);
			printf("\n");
			rd = add_data(0, data, l_pseudo+l_input, my_id, nonce, rd, n);
			pthread_mutex_unlock(&lock);
		}
	}
}
void* actualize_thread(void *ptr){
	pthread_mutex_lock(&lock);
	p_n = actualize_neighbours(s, n, p_n, my_id);
	pthread_mutex_unlock(&lock);
	while(1){
		sleep(30);
		pthread_mutex_lock(&lock);
		p_n = actualize_neighbours(s, n, p_n, my_id);
		pthread_mutex_unlock(&lock);
	}
}
void* share_neighbours_thread(void *ptr){
	while(1){
		sleep(120);
		pthread_mutex_lock(&lock);
		share_neighbours(s, n);
		pthread_mutex_unlock(&lock);
	}
}
void* file_thread(void* ptr){
	file_upload_deamon();
}

void read_tlv(uint8_t* tlv, struct sockaddr_in6* addr, uint16_t length){
	switch(tlv[0]){
    case 0:
      break;
    case 1:
      break;
		case 2:
			if(length >= 10) receive_hello(tlv, addr);
			else{
				printf("J'ai reçue un mauvais hello\n");
				neighbours* neigh = find_neighbour(addr->sin6_addr, addr->sin6_port, n);
				if(n) remove_list(n, neigh);
				go_away(s, &addr->sin6_addr, addr->sin6_port, 3, NULL, 0, NULL);
			}
			break;
    case 3:
			if(length <= 20){
				printf("J'ai reçue un mauvais neighbour\n");
				neighbours* neigh = find_neighbour(addr->sin6_addr, addr->sin6_port, n);
				if(n) remove_list(n, neigh);
				go_away(s, &addr->sin6_addr, addr->sin6_port, 3, NULL, 0, NULL);
			}
			else receive_neighbour(tlv, addr);
      break;
    case 4:
			if(length < 15){
				printf("J'ai reçue un mauvais data\n");
				neighbours* neigh = find_neighbour(addr->sin6_addr, addr->sin6_port, n);
				if(n) remove_list(n, neigh);
				go_away(s, &addr->sin6_addr, addr->sin6_port, 3, NULL, 0, NULL);
			}
			else receive_data(tlv, addr);
      break;
    case 5:
      if(length < 14){
				printf("J'ai reçue un mauvais ack\n");
				neighbours* neigh = find_neighbour(addr->sin6_addr, addr->sin6_port, n);
				if(n) remove_list(n, neigh);
				go_away(s, &addr->sin6_addr, addr->sin6_port, 3, NULL, 0, NULL);
			}
			else receive_ack(tlv, addr);
      break;
    case 6:
			if(length<3){
				neighbours* neigh = find_neighbour(addr->sin6_addr, addr->sin6_port, n);
				if(n) remove_list(n, neigh);
				go_away(s, &addr->sin6_addr, addr->sin6_port, 3, NULL, 0, NULL);
			}
			else receive_go_away(tlv, addr);
      break;
    case 7:
      receive_warning(tlv+2, tlv[1]);
      break;
		case 27:
			histo = receive_upload_request(tlv, addr, n, s, histo, len_histo);
			break;
		default:
			break;
	}
}
void read_message(uint8_t* msg, struct sockaddr_in6* addr){
	if(msg[0]==93){
		if(msg[1]==2){
				/* récupérer la body_length */
				uint16_t length;
				memcpy(&length, msg+2, 2);
				length = htons(length);
        read_tlv(msg+4, addr, length);
		}
		else printf("Wrong Version\n");
	}
	else printf("Wrong Magic\n");
}



int main(int argc, char** argv){
  /* Création du pseudo */
  printf("Pick a nickname (size<=10)\n");
  char buf[10];
  memset(buf, 0, 10);
  fgets(buf, 10, stdin);
  pseudo = malloc(sizeof(char)*(strlen(buf)+2));
  memset(pseudo, 0, strlen(buf)+2);
  memcpy(pseudo, buf, strlen(buf)-1);
  memcpy(pseudo+strlen(buf)-1, ": ", 2);

  /* On crée l'id aléatoire */
  my_id = malloc(sizeof(uint8_t)*8);
  memset(my_id, 0, 8);
  unsigned char random[8];
  int fd = open("/dev/urandom", O_RDONLY);
  if(fd<0){ /* Faire du random autrement */
    for(int i=0; i<8; i++) my_id[i] = rand()%255;
  }
  rc = read(fd, rand, 8);
  if(rc<0){ /* Faire du random */
    for(int i=0; i<8; i++) random[i] = rand()%255;
  }
  close(fd);
  memcpy(my_id, random, 8);

	/* Récupère les voisins */
	p_n = lire_voisin(p_n);

  /* Création socket */
  s = socket(PF_INET6, SOCK_DGRAM, 0);
  int reuse = 1, v6only = 0;
  rc = setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
  rc = setsockopt(s, IPPROTO_IPV6, IPV6_V6ONLY, &v6only, sizeof(v6only));

	if(argc>=2){
  	/* Mon addr que je bind */
	  struct sockaddr_in6 mon_addr;
	  memset(&mon_addr, 0, sizeof(mon_addr));
	  mon_addr.sin6_family = AF_INET6;
	  mon_addr.sin6_addr = in6addr_any;
	  mon_addr.sin6_port = htons(atoi(argv[1]));
	  rc = bind(s, (struct sockaddr*)&mon_addr, sizeof(mon_addr));
	  if(rc<0){
	    perror("bind");
	    exit(1);
	  }
	}

	/* Création thread pour l'innondation */
	pthread_t innondate;
	if(pthread_create(&innondate, NULL, innondate_thread, NULL)==-1){
		perror("pthread_create");
		exit(1);
	}


  /* Création thread pour entrée utilisateur */
  pthread_t read_input;
  if (pthread_create(&read_input, NULL, read_input_user, NULL)!=0){
    perror("pthread_create");
    exit(1);
  }
	/* Création thread pour actualiser mes données */
	pthread_t actualize;
	if(pthread_create(&actualize, NULL, actualize_thread, NULL)==-1){
		perror("pthread_create");
		exit(1);
	}
	/* Création thread pour partager les voisins */
	pthread_t share;
	if(pthread_create(&share, NULL, share_neighbours_thread, NULL)==-1){
		perror("pthread_create");
		exit(1);
	}

	/* Création thread pour serveur tcp */
	pthread_t file_transfert_deamon;
	if(pthread_create(&file_transfert_deamon, NULL, file_thread, NULL)==-1){
		perror("pthread_create");
		exit(1);
	}

	fcntl(s, F_SETFL, O_NONBLOCK);
	fd_set readfs;
	uint8_t r_msg[DATAGRAM_MAX_SIZE];
	while(1){
		FD_ZERO(&readfs);
		FD_SET(s, &readfs);
		pselect(s+1, &readfs, NULL, NULL, NULL, 0);
		if(FD_ISSET(s, &readfs)){
			struct sockaddr_in6 test;
			int len_test = sizeof(test);
			memset(r_msg, 0, DATAGRAM_MAX_SIZE);
			rc = recvfrom(s, r_msg, DATAGRAM_MAX_SIZE, 0, (struct sockaddr*)&test, &len_test);
			if(rc>0){
				pthread_mutex_lock(&lock);
				read_message(r_msg, &test);
				pthread_mutex_unlock(&lock);
			}
		}
	}
}
