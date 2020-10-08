#include "data.h"

recent_data* create_data(uint8_t type, uint8_t* data, int length, uint8_t* id, uint8_t* nonce){
  struct recent_data* new = malloc(sizeof(struct recent_data));
  new->id = id;
  new->nonce = nonce;
  new->size_data = length;
  new->data = malloc(sizeof(char)*length);
  memcpy(new->data, data, length);
  new->type = type;
  new->nb_to_innondate = 0;
  return new;
}
HeadList* add_data(uint8_t type, uint8_t* data, int length, uint8_t* id, uint8_t* nonce, HeadList* rd, HeadList* n){
  if(n==NULL || n->head==NULL) return NULL;
  struct recent_data* new = create_data(type, data, length, id, nonce);
  HeadList* list_inn  = NULL;
  LinkedList* aux = n->head;
  while(aux){
    // add_last(aux->ptr, innondation);
    neighbours* n = (neighbours*)aux->ptr;
    if(memcmp(id, n->id, 8)!=0){
      innondation* inn = malloc(sizeof(innondation));
      inn->tosend = n;
      inn->nb_sent = 0;
      inn->when = 0;
      inn->last_time_sent = malloc(sizeof(time_t));
      new->nb_to_innondate += 1;
      if(list_inn == NULL) list_inn = create(inn, INN);
      else add_last(inn, list_inn);
    }
    aux = aux->next;
  }
  new->innond = list_inn;
  if(rd==NULL || rd->head==NULL) rd = create(new, DATA);
  else add_last(new, rd);
  return rd;
}

short already_in(uint8_t id[8], uint8_t nonce[4], HeadList* list){
  if(list==NULL || list->head==NULL) return 0;
  LinkedList* aux = list->head;
  recent_data* rd;
  while(aux){
    rd = (recent_data*)aux->ptr;
    if(memcmp(id, rd->id, 8)==0 && memcmp(nonce, rd->nonce, 4)==0)
      return 1;
    aux = aux->next;
  }
  return 0;

}
void delete_innond(struct sockaddr_in6* from, HeadList* list){
  if(list==NULL || list->head==NULL) return;
  LinkedList* aux = list->head;
  innondation* in;
  while(aux){
    in = (innondation*)aux->ptr;
    if(memcmp(&from->sin6_addr, in->tosend->addr, sizeof(&from->sin6_addr))==0 && htons(in->tosend->port)==htons((uint16_t)from->sin6_port)){
      remove_list(list, in);
    }
    aux = aux->next;
  }
}
void delete_neighbour_innondation(struct sockaddr_in6* from, uint8_t sender_id[8], uint8_t nonce[4], HeadList* list){
  if(list==NULL || list->head==NULL) return;
  LinkedList* datas = list->head;
  recent_data* rd;
  while(datas){
    rd = (recent_data*)datas->ptr;
    if(memcmp(sender_id, rd->id, 8)==0 && memcmp(nonce, rd->nonce, 4)==0){
      delete_innond(from, rd->innond);
      if(rd->innond==NULL || rd->innond->head==NULL){ /* plus de voisins */
        remove_list(list, rd);
      }
    }
    datas = datas->next;
  }
}

void innondate_neighbours(int socket, HeadList* list_data, recent_data* r_data, time_t* now){
  if(r_data->innond == NULL) return;
  HeadList* list = r_data->innond;
  LinkedList* aux = list->head;
  innondation* inn;
  while(aux){
    inn = (innondation*)aux->ptr;
    short send = 0;
    if(inn->last_time_sent==NULL) send = 1;
    else{
      if(difftime(*now, *inn->last_time_sent)>=inn->when)
      send = 1;
    }
    if(send){
      send_data(socket, inn->tosend->addr, inn->tosend->port, r_data->id, r_data->nonce, r_data->type, r_data->data, r_data->size_data, &inn->tosend->pmtu);
      if(inn->last_time_sent==NULL){
        time_t* t = malloc(sizeof(time_t));
        memset(t, 0, sizeof(t));
        time(t);
        inn->last_time_sent = t;
      }
      else{
        time(inn->last_time_sent);
      }
      inn->nb_sent += 1;
      if(inn->nb_sent==1) inn->when = 3;
      else{
        int borne_min = pow(2, inn->nb_sent-1);
        int borne_max = pow(2, inn->nb_sent);
        int when = rand()%(borne_max - borne_min) + borne_min;
        inn->when = when;
      }
      if(inn->nb_sent>=5){
        go_away(socket, inn->tosend->addr, inn->tosend->port, 2, NULL, 0, &inn->tosend->pmtu);
        remove_list(r_data->innond, inn);
        if(r_data->innond==NULL){
          remove_list(list_data, r_data);
        }
      }
    }
    aux = aux->next;
  }
}
void innondate(int socket, HeadList* rd, time_t* now){
  if(rd==NULL || rd->head==NULL) return;
  LinkedList* datas = rd->head;
  recent_data* r_data;
  while(datas){
    r_data = (recent_data*)datas->ptr;
    if(r_data->nb_to_innondate>0){
      innondate_neighbours(socket, rd, r_data, now);
    }
    datas = datas->next;
  }
}
