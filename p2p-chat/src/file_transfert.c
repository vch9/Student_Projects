
#include <dirent.h>
#include <sys/stat.h>
#include "file_transfert.h"
#include "message.h"
#include "struct.h"
#include "list.h"
#include "receive_msg.h"

#define BUFFER_SIZE 1024



HeadList *uploads = NULL;
HeadList *downloads = NULL;

HeadList* add_to_file_list(HeadList *list, struct file_struct *item);

struct file_struct *get_from_upload_list(HeadList* list, uint16_t ntohs) {
    if(list==NULL || list->head==NULL) return  NULL;
    LinkedList* aux = list->head;
    struct file_struct* file;
    while(aux){
      file = (struct file_struct*)aux->ptr;
      if(ntohs==file->id) return file;
      aux = aux->next;
    }
    return NULL;
}

historique** send_upload_request(char *path, int socket, struct in6_addr *addr, in_port_t port, uint8_t id[8], int *pmtu, historique** histo, int len_histo) {
    /* On ouvre le fichier pour vérifier qu'il existe*/
    FILE *fptr = fopen(path, "r");

    if (!fptr) {
        printf("Ouverture du fichier impossible.");
        // return -1;
        return histo;
    }

    struct file_struct *p_upload_item = calloc(1,sizeof(struct file_struct));

    p_upload_item->client_addr = *addr;
    p_upload_item->client_port = port;
    strcpy(p_upload_item->file_path, path);
    p_upload_item->id = (uint16_t) rand();

    //On récupère la taille du fichier
    fseek(fptr, 0, SEEK_END);
    long fileSize = ftell(fptr);


    //On crée le tlv
    uint8_t body[67];
    memset(body, 0, 67);

    // ID
    memcpy(body, id, 8);

    //NONCE
    uint8_t* nonce = malloc(sizeof(uint8_t)*8);
    for(int i=0; i<4; i++)
      nonce[i] = rand()%255;
    memcpy(body+8,&nonce,4);

    histo = add_histo(histo, len_histo, id, nonce);

    // ID FICHIER
    uint16_t n_id;
    memcpy(body + 12, &n_id, 2);

    body[14] = 0; // 0 pour "Pas d'information sur l'adresse"

    //Adresse vide de 16 octets

    //TAILLE DU FICHIER
    memcpy(body + 31, &fileSize, 4);

    //NOM
    memcpy(body + 35, basename(p_upload_item->file_path), strlen(p_upload_item->file_path));

    uint8_t *tlv = createTLV(27, 67, body);
    if (0 > send_message(socket, addr, port, tlv, 67, pmtu)) {
        printf("\nEnvoie du message échoué");
        // return -1;
        return histo;
    }
    uploads = add_to_file_list(uploads, p_upload_item);

    /*Si tout s'est bien passé, on crée le serveur tcp qui va uploadera le fichier*/

    return histo;

}

HeadList* add_to_file_list(HeadList* list, struct file_struct *item) {
    if(list==NULL || list->head == NULL) list = create(item, FICHIER);
    else add_last(item, list);
    return list;
}


short display_download_request(uint8_t *sender_id, uint16_t file_id, uint32_t file_size, uint8_t *file_name);

historique** receive_upload_request(uint8_t *tlv, struct sockaddr_in6 *addr, HeadList *neighbours_head, int s, historique** histo, int len_histo) {
    uint8_t *sender_id = NULL;

    //ID
    sender_id = malloc(sizeof(uint8_t) * 8);
    memset(sender_id, 0, 8);
    memcpy(sender_id, tlv + 2, 8);

    //NONCE
    uint8_t* nonce = malloc(sizeof(uint8_t)*8);
    memcpy(&nonce, tlv + 10, 4);

    if(already_received(histo, len_histo, sender_id, nonce)){
      free(sender_id);
      free(nonce);
      return histo;
    }
    else{
      histo = add_histo(histo, len_histo, sender_id, nonce);
    }
    //ID_FICHIER
    uint16_t file_id;
    memcpy(tlv + 14, &file_id, 2);
    file_id = htons(file_id);

    //ADRESS
    uint8_t hasAdress;
    memcpy(tlv+16, &hasAdress,1);

    uint8_t *adress = calloc(16, sizeof(uint8_t));
    memcpy(tlv+17, &adress,16);

    //TAILLE DU FICHIER
    uint32_t file_size;
    memcpy(tlv + 33,&file_size, sizeof(uint32_t));
    file_size = htonl(file_size);

    //NOM
    uint8_t *file_name = calloc(32,sizeof(uint8_t));;
    memcpy(file_name, tlv + 37, 32);



    struct file_struct * download_item = calloc(1,sizeof(struct file_struct));
    download_item->id=file_id;
    strncpy(download_item->file_path, file_name, strlen(file_name));

    if(!hasAdress) {
        download_item->client_sockaddr = *addr;

        //On modifie le tlv pour l'envoyer à ses voisins
        memcpy(tlv + 16, &addr->sin6_addr, 16);
    }

    if(neighbours_head && neighbours_head->head){
        LinkedList* aux = neighbours_head->head;
        while(aux){
            neighbours* neigh = (neighbours*)aux->ptr;

            send_message(s,neigh->addr,neigh->port,tlv,67,&neigh->pmtu);
            aux = aux->next;
        }
    }
    display_download_request(sender_id, file_id, file_size, file_name);
    downloads = add_to_file_list(downloads,download_item);

    return histo;
}

void accept_file(uint16_t file_id) {
  printf("accept_file\n");
    struct file_struct *download_item = get_from_upload_list(downloads, file_id);
    if(!download_item){
        printf("Fichier non trouvé\n");
        return;
    }
    char* file_name = download_item->file_path;
    struct sockaddr_in6 *pIn6 = &download_item->client_sockaddr;

    printf("socket\n");

    //Création de la socket

    int s = socket(PF_INET6, SOCK_STREAM, 0);
    int val = 0;
    setsockopt(s, IPPROTO_IPV6, IPV6_V6ONLY, &val, sizeof(val));
    if (0 > s) {
        perror("Socket :");
    }


    int rc = connect(s, (const struct sockaddr *) pIn6, sizeof(struct sockaddr_in6));
    if (rc < 0) perror("connect :");

    write(s, &file_id, sizeof(file_id));


    //FILE * file;
    //On vérifie si le dossier download existe
    DIR* dir = opendir("download");
    if(!dir){
        mkdir("download",0700);
    }closedir(dir);

    char file_path[BUFFER_SIZE + 100];
    char *path = "./download/";
    strcpy(file_path, path);
    strcat(file_path, file_name);
    FILE *file = fopen(file_path, "ab");
    if (!file) perror("open\n");

    char buffer[BUFFER_SIZE];
    int c;
    while (c = read(s, buffer, BUFFER_SIZE) > 0) {
        fwrite(buffer, 1, c, file);
    }
    printf("Fichier téléchargé à l'emplacement : %s\n", file_path);
}

void file_upload_deamon() {
    int s = socket(PF_INET6, SOCK_STREAM, 0);
    struct sockaddr_in6 server;
    memset(&server, 0, sizeof(server));
    server.sin6_family = AF_INET6;
    server.sin6_port = htons(1313);
    //server.sin_addr = in6addr_any;

    int rc = bind(s, (const struct sockaddr *) &server, sizeof(server));
    if (0 > rc) perror("bind");


    rc = listen(s, 1024);
    if (0 > rc) perror("listen");

    uint16_t req = 0;
    struct file_struct *aStruct;

    while (1) {
        int s2 = accept(s, NULL, NULL);
        if (s2 < 0)perror("accept\n");

        rc = (int) read(s2, &req, sizeof(uint16_t));
        if (0 > rc) {
            printf("Echec du read()");
            perror("read");
        }

        if (aStruct = (get_from_upload_list(NULL, ntohs(req)))) {//DEBUG if(aStruct = get_from_upload_list(ntohs(req))

            //On ouvre le fichier en question
            FILE *file = fopen(aStruct->file_path, "rb");

            if (!file) {
                printf("Fichier non trouvé\n");
                break;
            }

            char buffer[BUFFER_SIZE] = {0};
            int c;
            while (!feof(file)) {
                c = fread(buffer, 1, BUFFER_SIZE, file);
                write(s2, buffer, c);
            }
            fseek(file, 0, SEEK_SET);

        }
        close(s2);
    }
}

short display_download_request(uint8_t *sender_id, uint16_t file_id, uint32_t file_size, uint8_t *file_name) {
    char text[400];
    sprintf(text, "Voulez vous télécharger le fichier: nom : %s\ntaille : %u \n!dl %u pour le télécharger", file_name, file_size, file_id);
    printf("%s\n", text);
}
