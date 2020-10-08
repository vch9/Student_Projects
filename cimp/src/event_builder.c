//
// Created by benjamin on 28/02/19.
//

#include "event_builder.h"


void buildEvent(int data) {
    Uint32 myEventType = SDL_RegisterEvents(EVENT_ZOOM);
    if (myEventType != ((Uint32) -1)) {
        SDL_Event event;
        SDL_memset(&event, 0, sizeof(event)); /* or SDL_zero(event) */
        event.type = myEventType;
        //event.user.code = "jk";
        //event.user.data1 = data;
        event.user.data2 = 0;
        SDL_PushEvent(&event);
    }

}
