#include "tlv_builder.h"



uint8_t* createMessage(uint8_t magic, uint8_t version, uint16_t body_length, uint8_t *body){
    uint8_t* message = malloc(sizeof(uint8_t)*(body_length+4+1));
    memset(message, 0, body_length+4);
    message[0] = magic;
    message[1] = version;
    memcpy(message+4, body, body_length);
    body_length = htons(body_length);
    memcpy(message+2, &body_length, 2);
    return message;
    // return "";
}
uint8_t* createTLV(uint8_t type, uint8_t body_length, uint8_t* body){
    uint8_t* tlv = malloc(sizeof(uint8_t)*(body_length+2));
    memset(tlv, 0, body_length+2);

    tlv[0] = type;
    tlv[1] = body_length;

    memcpy(tlv+2, body, body_length);
    return tlv;
}
