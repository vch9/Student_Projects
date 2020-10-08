
#ifndef RESEAU_FILE_TRANSFERT_H
#define RESEAU_FILE_TRANSFERT_H


#include <stdlib.h>
#include <stdio.h>
#include "file_transfert.h"
#include "tlv_builder.h"
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <libgen.h>
#include "message.h"
#include "uthash.h"
#include "struct.h"
#include "list.h"


historique** send_upload_request(char *path, int socket, struct in6_addr *addr, in_port_t port, uint8_t id[8], int *pmtu, historique** histo, int len_histo);

historique** receive_upload_request(uint8_t *tlv, struct sockaddr_in6 *addr, HeadList *neighbours_head, int s, historique** histo, int len_histo);

void file_upload_deamon();

void accept_file(uint16_t file_id);

#endif //RESEAU_FILE_TRANSFERT_H
        //
